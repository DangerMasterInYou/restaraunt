"""Общие зависимости проверки доступа (роли + валидность токена).

Все проверки обращаются к БД: токен (jti) должен существовать (не отозван при
logout / блокировке / удалении), а пользователь — быть активным. Это гарантирует,
что заблокированные/удалённые пользователи теряют доступ немедленно на ЛЮБОМ
эндпоинте, а не только там, где раньше проверялся jti.
"""

from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.db_helper import db_helper
from core.models import User, Token
from api.api_v1.auth_jwt.crud_validation import get_current_token_payload

_http_bearer = HTTPBearer()


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(_http_bearer)],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
) -> User:
    payload = get_current_token_payload(credentials=credentials)

    jti = payload.get("jti")
    if jti is not None:
        token = await session.scalar(select(Token).where(Token.jti == jti))
        if token is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Токен недействителен (отозван).",
            )

    sub = payload.get("sub")
    user = await session.get(User, int(sub)) if sub is not None else None
    if user is None or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Пользователь заблокирован или не существует.",
        )
    return user


def _role_str(user: User) -> str:
    role = user.role
    return role.value if hasattr(role, "value") else str(role)


async def get_current_user_role(
    user: Annotated[User, Depends(get_current_user)],
) -> str:
    return _role_str(user)


async def require_operator_or_admin(
    user: Annotated[User, Depends(get_current_user)],
) -> User:
    if _role_str(user) not in ("operator", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Требуется роль оператора или администратора",
        )
    return user


async def require_admin(
    user: Annotated[User, Depends(get_current_user)],
) -> User:
    if _role_str(user) != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Требуется роль администратора",
        )
    return user


async def get_current_active_user_id(
    user: Annotated[User, Depends(get_current_user)],
) -> int:
    """ID активного пользователя с валидным токеном (для client-эндпоинтов)."""
    return user.id
