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


# Генерация кода
def generation_verification_code():
    import secrets
    import string

    # # Генерация более безопасного кода с использованием букв и цифр
    # alphabet = string.ascii_letters + string.digits
    # return ''.join(secrets.choice(alphabet) for _ in range(8))

    # Или если нужны только цифры, используйте более безопасный метод
    return "".join(secrets.choice(string.digits) for _ in range(6))


async def request_code(
    user_data: EmailRequestScheme,
    session: AsyncSession,
    verification_code: str,
):
    try:
        email: EmailStr = user_data.email
        # Проверка существования пользователя
        user: User | None = await session.scalar(
            select(User).where(User.email == email)
        )

        # Установка времени истечения срока кода
        expires_at: datetime = datetime.utcnow() + timedelta(
            minutes=settings.auth_jwt.verification_code_expire_minutes
        )

        if user is None:
            # регистрация нового пользователя
            user = User(
                email=user_data.email,
                verification_code=verification_code,
                verification_code_expires_at=expires_at,
            )
            session.add(user)
        else:
            user.verification_code = verification_code
            user.verification_code_expires_at = expires_at

        await session.commit()
        return EmailResponseScheme(
            success=True,
            message="Код отправлен на email",
        )
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


async def get_valid_user_data_for_auth(
    data: LoginSchema,
    session: AsyncSession,
) -> User:
    user: User | None = await session.scalar(
        select(User).where(User.email == data.email)
    )
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    # Проверка, что пользователь активен
    if user.is_active is False:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User inactive or deleted",
        )

    # Проверка кода
    if user.verification_code != data.code:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Invalid code"
        )

    # Проверка срока действия кода
    if (
        user.verification_code_expires_at
        and user.verification_code_expires_at < datetime.utcnow()
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Verification code has expired",
        )
    return user


async def verify_code_and_login(
    data: LoginSchema,
    session: AsyncSession,
):
    user: User = await get_valid_user_data_for_auth(data=data, session=session)

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

    # сохранение jti токена
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
