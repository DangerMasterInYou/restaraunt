from typing import Annotated, Optional, Dict, Any, List
from pydantic import BaseModel

from fastapi import APIRouter, BackgroundTasks, status, Depends, HTTPException
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
from sqlalchemy import text

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


class SQLQueryRequest(BaseModel):
    query: str
    params: Optional[Dict[str, Any]] = None


class SQLQueryResponse(BaseModel):
    success: bool
    data: Optional[List[Dict[str, Any]]] = None
    message: Optional[str] = None
    rowcount: Optional[int] = None


@router.post(
    "/execute-sql",
    response_model=SQLQueryResponse,
    status_code=status.HTTP_200_OK,
)
async def execute_sql_query(
    request: SQLQueryRequest,
    session: AsyncSession = Depends(db_helper.session_getter),
):
    try:
        # Преобразуем строку в текстовый SQL‑запрос
        sql_query = text(request.query)

        # Выполняем запрос с параметрами
        result = await session.execute(sql_query, request.params or {})
        await session.commit()

        # Обрабатываем результат
        if result.returns_rows:
            rows = result.mappings().all()
            data = [dict(row) for row in rows]
        else:
            data = None

        return SQLQueryResponse(
            success=True,
            data=data,
            rowcount=result.rowcount,
        )
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=f"Ошибка SQL: {str(e)}"
        )
