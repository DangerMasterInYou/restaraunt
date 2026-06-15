"""#1: In-memory хранилище кодов подтверждения e-mail.

Зачем: до подтверждения кода НЕ должно быть записи в БД (защита от засорения
таблицы users и от брутфорса через создание мусорных аккаунтов). Серверная
защита от перебора: счётчик неверных кодов и временная блокировка email.

Хранилище живёт в памяти процесса (один воркер в Docker). Коды короткоживущие,
потеря состояния при рестарте безопасна — пользователь просто запросит код заново.
"""

import time
from dataclasses import dataclass, field
from typing import Optional


MAX_ATTEMPTS = 5
BLOCK_SECONDS = 60
RESEND_COOLDOWN = 30


@dataclass
class _Entry:
    code: str
    expires_at: float
    attempts: int = 0
    blocked_until: float = 0.0
    last_sent: float = 0.0


_store: dict[str, _Entry] = {}


def _key(email: str) -> str:
    return email.strip().lower()


def block_remaining(email: str) -> int:
    """Сколько секунд осталось до конца блокировки (0 — не заблокирован)."""
    e = _store.get(_key(email))
    if not e:
        return 0
    rem = int(e.blocked_until - time.time())
    return rem if rem > 0 else 0


def resend_remaining(email: str) -> int:
    """Сколько секунд осталось до возможности повторной отправки кода."""
    e = _store.get(_key(email))
    if not e:
        return 0
    rem = int(e.last_sent + RESEND_COOLDOWN - time.time())
    return rem if rem > 0 else 0


def save_code(email: str, code: str, ttl_seconds: int) -> None:
    """Сохранить новый код: сбрасывает счётчик попыток для нового кода."""
    k = _key(email)
    now = time.time()
    _store[k] = _Entry(
        code=code,
        expires_at=now + ttl_seconds,
        attempts=0,
        blocked_until=0.0,
        last_sent=now,
    )


def verify(email: str, code: str) -> tuple[bool, int, int]:
    """Проверить код.

    Возвращает (ok, attempts_left, block_remaining_sec).
    При исчерпании попыток выставляет блокировку и обнуляет код.
    """
    k = _key(email)
    e = _store.get(k)
    now = time.time()

    if not e or e.expires_at < now:
        return False, 0, 0

    rem = int(e.blocked_until - now)
    if rem > 0:
        return False, 0, rem

    if e.code and code == e.code:
        _store.pop(k, None)
        return True, MAX_ATTEMPTS, 0

    e.attempts += 1
    left = MAX_ATTEMPTS - e.attempts
    if left <= 0:
        e.blocked_until = now + BLOCK_SECONDS
        e.code = ""
        e.attempts = 0
        return False, 0, BLOCK_SECONDS
    return False, left, 0
