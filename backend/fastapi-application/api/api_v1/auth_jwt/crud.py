from fastapi import HTTPException
from fastapi.security import (
    HTTPAuthorizationCredentials,
)
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError
from starlette import status

from auth import utils as auth_utils
import logging
import uuid

from core.models import User, Token
from .crud_validation import (
    auth_user_validate,
    token_count_check,
    validation_user_registration,
    get_current_token_payload,
)
from .schemas import (
    UserRegisterScheme,
    UserLoginScheme,
    LoginResponseScheme,
    UserRead,
)


async def authorization_user(
    user_data: UserLoginScheme,
    session: AsyncSession,
):

    user = await auth_user_validate(user_data, session)
    # Создание JWT
    jwt_payload = {
        "sub": user.email,
        "email": user.email,
        "jti": str(uuid.uuid4()),
    }
    token = auth_utils.encode_jwt(jwt_payload)

    await token_count_check(user, session)

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
        logging.error(f"Ошибка при создании токена: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Ошибка при авторизации",
        )

    return LoginResponseScheme(
        access_token=token,
        email=user.email,
        token_type="bearer",
    )


async def user_registration(
    user_data: UserRegisterScheme,
    session: AsyncSession,
) -> UserRead:
    await validation_user_registration(
        user_data=user_data,
        session=session,
    )
    try:
        # создание пользователя
        user = User(
            email=user_data.email,
            password=auth_utils.hash_password(user_data.password),
            phone=user_data.phone,
            first_name=user_data.first_name,
            last_name=user_data.last_name,
            birthday=user_data.birthday,
        )

        session.add(user)
        await session.commit()
        await session.refresh(user)

        logging.info(f"Пользователь с email {user.email} успешно зарегистрирован")
        user_result = UserRead(
            email=user.email,
            birthday=user.birthday,
            first_name=user.first_name,
            last_name=user.last_name,
            phone=user.phone,
            is_active=user.is_active,
            created_at=user.created_at,
        )
        return user_result
    except IntegrityError as e:
        await session.rollback()
        logging.error(f"Ошибка целостности данных: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Ошибка при сохранении данных пользователя",
        )

    except Exception as e:
        await session.rollback()
        logging.error(f"Ошибка при регистрации пользователя: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Произошла ошибка при регистрации пользователя",
        )


async def get_current_auth_user(
    session: AsyncSession,
    credentials: HTTPAuthorizationCredentials,
) -> UserRead:
    payload = get_current_token_payload(credentials=credentials)
    stmt = select(Token).where(Token.jti == payload["jti"])
    token_result = await session.execute(stmt)
    token = token_result.scalar_one_or_none()

    if token is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Токен недействителен (не найден в базе данных)",
        )

    stmt = select(User).where(User.email == payload["email"])
    if user := await session.scalar(stmt):
        user_result = UserRead(
            email=user.email,
            birthday=user.birthday,
            first_name=user.first_name,
            last_name=user.last_name,
            phone=user.phone,
            is_active=user.is_active,
            created_at=user.created_at,
        )
        return user_result
    else:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Токен недействителен (пользователь не найден)",
        )


async def logout_user(
    session: AsyncSession,
    credentials: HTTPAuthorizationCredentials,
):
    payload = get_current_token_payload(credentials=credentials)
    stmt = select(Token).where(Token.jti == payload["jti"])
    token_result = await session.execute(stmt)
    token_to_delete = token_result.scalar_one_or_none()

    if token_to_delete is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Токен недействителен или уже был использован для выхода",
        )

    await session.delete(token_to_delete)
    await session.commit()
