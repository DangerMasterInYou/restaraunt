from typing import Annotated

from fastapi import APIRouter, BackgroundTasks, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from core.db_helper import db_helper

from .utils.verify_email import send_verification_code
from .schemas import (
    EmailRequestScheme,
    EmailResponseScheme,
    LoginSchema,
    ResponseLoginSchema,
)
from . import crud

router = APIRouter()

http_bearer = HTTPBearer()


@router.post(
    "/send-code",
    response_model=EmailResponseScheme,
    status_code=status.HTTP_200_OK,
)
async def request_verification_code(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_data: EmailRequestScheme,
    background_tasks: BackgroundTasks,
):
    verification_code: str = crud.generation_verification_code()

    background_tasks.add_task(
        send_verification_code,
        recipient=str(user_data.email),
        verification_code=verification_code,
    )
    return await crud.request_code(
        user_data=user_data, verification_code=verification_code, session=session
    )


@router.post(
    "/verify-code",
    response_model=ResponseLoginSchema,
    status_code=status.HTTP_200_OK,
)
async def verify_code(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    data: LoginSchema,
):
    return await crud.verify_code_and_login(data=data, session=session)
