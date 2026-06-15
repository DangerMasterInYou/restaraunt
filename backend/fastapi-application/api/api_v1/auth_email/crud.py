import uuid
from datetime import datetime, timedelta

from fastapi import HTTPException, status
from pydantic import EmailStr
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from auth import utils as auth_utils
from core.config import settings

from core.models import User, Token

from .schemas import (
    EmailRequestScheme,
    EmailResponseScheme,
    LoginSchema,
    ResponseLoginSchema,
    ResponseUserDataScheme,
)

from .helpers import token_count_check
from . import pending_store
from .utils.verify_email import send_verification_code


def generation_verification_code():
    import secrets
    import string


    return "".join(secrets.choice(string.digits) for _ in range(6))


async def request_code(
    user_data: EmailRequestScheme,
    session: AsyncSession,
    background_tasks,
):
    """#1: отправка кода БЕЗ записи в БД.

    Код хранится в памяти (pending_store) до подтверждения, чтобы неподтверждённая
    почта не оставляла запись в users. Здесь же — серверная блокировка перебора
    и анти-спам на повторную отправку.
    """
    email = str(user_data.email)

    blocked = pending_store.block_remaining(email)
    if blocked > 0:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "message": f"Слишком много попыток. Подождите {blocked} с.",
                "blocked_seconds": blocked,
            },
        )

    cooldown = pending_store.resend_remaining(email)
    if cooldown > 0:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "message": f"Код уже отправлен. Повторить можно через {cooldown} с.",
                "resend_seconds": cooldown,
            },
        )

    verification_code = generation_verification_code()
    ttl_seconds = settings.auth_jwt.verification_code_expire_minutes * 60
    pending_store.save_code(email, verification_code, ttl_seconds)

    background_tasks.add_task(
        send_verification_code,
        recipient=email,
        verification_code=verification_code,
    )
    return EmailResponseScheme(
        success=True,
        message="Код отправлен на email",
    )


async def verify_code_and_login(
    data: LoginSchema,
    session: AsyncSession,
):
    email = str(data.email)

    ok, attempts_left, block_rem = pending_store.verify(email, data.code)
    if not ok:
        if block_rem > 0:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail={
                    "message": "Слишком много попыток. Подождите.",
                    "blocked_seconds": block_rem,
                    "attempts_left": 0,
                },
            )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "message": "Неверный или просроченный код",
                "attempts_left": attempts_left,
            },
        )

    user: User | None = await session.scalar(
        select(User).where(User.email == data.email)
    )
    if user is None:
        user = User(
            email=data.email,
            verification_code="",
            verification_code_expires_at=datetime.utcnow(),
        )
        session.add(user)
        await session.flush()
    elif user.is_active is False:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"message": "Пользователь деактивирован"},
        )

    jwt_payload = {
        "sub": str(user.id),
        "email": user.email,
        "role": user.role,
        "jti": str(uuid.uuid4()),
    }
    token: str = auth_utils.encode_jwt(jwt_payload)

    await token_count_check(user, session)
    user.verification_code = ""
    user.verification_code_expires_at = datetime.utcnow()

    try:
        token_info = Token(
            user_id=user.id,
            jti=jwt_payload["jti"],
        )
        session.add(token_info)
        await session.commit()
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Ошибка при авторизации",
        )

    return ResponseLoginSchema(
        success=True,
        token=token,
        user=ResponseUserDataScheme(
            id=user.id,
            email=user.email,
            role=user.role,
        ),
    )
