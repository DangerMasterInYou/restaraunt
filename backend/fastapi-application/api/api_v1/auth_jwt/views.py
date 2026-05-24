from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from core.db_helper import db_helper
from .schemas import UserRegisterScheme, UserRead, UserLoginScheme
from . import crud

router = APIRouter()


http_bearer = HTTPBearer()


@router.post("/login")
async def login(
    user: UserLoginScheme,
    session: Annotated[
        AsyncSession,
        Depends(db_helper.session_getter),
    ],
):
    return await crud.authorization_user(
        user_data=user,
        session=session,
    )


@router.post(
    "/register",
    response_model=UserRead,
)
async def register(
    user: UserRegisterScheme,
    session: Annotated[
        AsyncSession,
        Depends(db_helper.session_getter),
    ],
):
    return await crud.user_registration(user_data=user, session=session)


@router.get(
    "/profile",
    response_model=UserRead,
)
async def profile(
    session: Annotated[
        AsyncSession,
        Depends(db_helper.session_getter),
    ],
    credentials: Annotated[
        HTTPAuthorizationCredentials,
        Depends(http_bearer),
    ],
):
    return await crud.get_current_auth_user(session=session, credentials=credentials)


@router.post(
    "/logout",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def logout(
    session: Annotated[
        AsyncSession,
        Depends(db_helper.session_getter),
    ],
    credentials: Annotated[
        HTTPAuthorizationCredentials,
        Depends(http_bearer),
    ],
):
    await crud.logout_user(
        session=session,
        credentials=credentials,
    )
