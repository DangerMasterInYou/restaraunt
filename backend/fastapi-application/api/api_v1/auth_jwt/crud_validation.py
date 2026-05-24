from typing import Annotated

from fastapi import HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jwt import InvalidTokenError
from sqlalchemy import select, or_
from sqlalchemy.ext.asyncio import AsyncSession
from starlette import status

from api.api_v1.auth_jwt.schemas import UserLoginScheme, UserRegisterScheme
from auth import utils as auth_utils
from core.models import User, Token


async def auth_user_validate(
    user_data: UserLoginScheme,
    session: AsyncSession,
) -> User:
    # Проверка пользователя
    unauthed_exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="invalid username or password",
    )
    stmt = select(User).where(User.email == user_data.email)
    if not (user := await session.scalar(stmt)):
        raise unauthed_exc
    if not auth_utils.validate_password(
        password=user_data.password,
        hashed_password=user.password,
    ):
        raise unauthed_exc
    return user


async def token_count_check(
    user: User,
    session: AsyncSession,
):
    # Проверка количество токенов
    token_query = await session.execute(select(Token).where(Token.user_id == user.id))
    active_tokens = token_query.scalars().all()

    if len(active_tokens) >= 10:
        for user_data_token in active_tokens[: len(active_tokens) - 9]:
            await session.delete(user_data_token)


async def validation_user_registration(
    user_data: UserRegisterScheme,
    session: AsyncSession,
) -> None:
    # проверка на существующего пользователя
    conditions = [User.email == user_data.email]
    if user_data.phone:
        conditions.append(User.phone == user_data.phone)
    stmt = select(User).where(or_(*conditions))

    existing_user = await session.execute(stmt)
    existing_user = existing_user.scalar()
    if existing_user is not None:
        detail = "Email уже зарегистрирован"
        if (
            existing_user.email != user_data.email
            and user_data.phone
            and existing_user.phone == user_data.phone
        ):
            detail = "Номер телефона уже зарегистрирован"

        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=detail,
        )


# парсим токен и получаем payload
http_bearer = HTTPBearer()


def get_current_token_payload(
    credentials: HTTPAuthorizationCredentials,
):
    try:
        payload = auth_utils.decode_jwt(token=str(credentials.credentials))
    except InvalidTokenError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"invalid token error: {e}",
        )
    return payload


http_bearer_scheme = HTTPBearer()


def get_current_user_id(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(http_bearer_scheme)],
) -> int:
    payload = get_current_token_payload(credentials=credentials)
    user_id: int | None = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Не удалось определить пользователя по токену.",
        )

    return int(user_id)
