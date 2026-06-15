"""Минимальный клиент ЮKassa на стандартной библиотеке (без новых зависимостей).

Используем urllib в отдельном потоке (asyncio.to_thread), чтобы не блокировать
event loop. Авторизация — HTTP Basic shop_id:secret_key.

Документация: https://yookassa.ru/developers/api#create_payment
"""

from __future__ import annotations

import asyncio
import base64
import json
import urllib.error
import urllib.request
import uuid

from core.config import settings

_API_URL = "https://api.yookassa.ru/v3/payments"
_REFUND_URL = "https://api.yookassa.ru/v3/refunds"


def is_configured() -> bool:
    """Готова ли интеграция (есть shop_id и секретный ключ)."""
    return bool(settings.api_yookassa.shop_id and settings.api_yookassa.web)


def _auth_header() -> str:
    raw = f"{settings.api_yookassa.shop_id}:{settings.api_yookassa.web}"
    return "Basic " + base64.b64encode(raw.encode()).decode()


def _request(url: str, *, method: str, body: dict | None = None) -> dict:
    data = json.dumps(body).encode() if body is not None else None
    headers = {
        "Authorization": _auth_header(),
        "Content-Type": "application/json",
    }
    if method == "POST":
        headers["Idempotence-Key"] = str(uuid.uuid4())
    req = urllib.request.Request(url, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"ЮKassa {exc.code}: {detail}") from exc


def _create_sync(amount: int, description: str, order_id: int, return_url: str) -> dict:
    return _request(
        _API_URL,
        method="POST",
        body={
            "amount": {"value": f"{amount:.2f}", "currency": "RUB"},
            "capture": True,
            "confirmation": {"type": "redirect", "return_url": return_url},
            "description": description,
            "metadata": {"order_id": order_id},
        },
    )


def _get_sync(payment_id: str) -> dict:
    return _request(f"{_API_URL}/{payment_id}", method="GET")


def _refund_sync(payment_id: str, amount: int) -> dict:
    return _request(
        _REFUND_URL,
        method="POST",
        body={
            "payment_id": payment_id,
            "amount": {"value": f"{amount:.2f}", "currency": "RUB"},
        },
    )


async def create_payment(
    amount: int, description: str, order_id: int, return_url: str
) -> dict:
    """Создаёт платёж, возвращает объект ЮKassa (с confirmation.confirmation_url)."""
    return await asyncio.to_thread(
        _create_sync, amount, description, order_id, return_url
    )


async def get_payment(payment_id: str) -> dict:
    """Запрашивает статус платежа (для подтверждения после возврата клиента)."""
    return await asyncio.to_thread(_get_sync, payment_id)


async def create_refund(payment_id: str, amount: int) -> dict:
    """Возврат средств по платежу ЮKassa (полный или частичный)."""
    return await asyncio.to_thread(_refund_sync, payment_id, amount)
