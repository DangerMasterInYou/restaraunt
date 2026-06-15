from typing import Annotated, List
from fastapi import APIRouter, Depends, Path, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from core.db_helper import db_helper
from api.api_v1.orders.views import require_admin
from core.models import User
from . import crud
from .schemas import (
    UserAdminResponse,
    UserRoleUpdate,
    UserActiveUpdate,
    UserAdminCreate,
    UserAdminUpdate,
)

router = APIRouter(
    prefix="/users", tags=["Admin Users"], dependencies=[Depends(require_admin)]
)


@router.get("", response_model=List[UserAdminResponse])
async def list_users(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
):
    return await crud.get_all_users(session, skip, limit)


@router.post("", response_model=UserAdminResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    data: UserAdminCreate,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.create_user_admin(session, data)


@router.patch("/{user_id}", response_model=UserAdminResponse)
async def update_user(
    user_id: int,
    data: UserAdminUpdate,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    actor: Annotated[User, Depends(require_admin)],
):
    return await crud.update_user_admin(session, user_id, data, actor)


@router.get("/{user_id}", response_model=UserAdminResponse)
async def get_user(
    user_id: int,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.get_user_by_id(session, user_id)


@router.patch("/{user_id}/role", response_model=UserAdminResponse)
async def change_user_role(
    user_id: int,
    role_data: UserRoleUpdate,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    actor: Annotated[User, Depends(require_admin)],
):
    return await crud.update_user_role(session, user_id, role_data, actor)


@router.patch("/{user_id}/active", response_model=UserAdminResponse)
async def change_user_active(
    user_id: int,
    active_data: UserActiveUpdate,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    actor: Annotated[User, Depends(require_admin)],
):
    return await crud.update_user_active(session, user_id, active_data, actor)


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_user(
    user_id: int,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    actor: Annotated[User, Depends(require_admin)],
    hard: bool = Query(False, description="true — удалить безвозвратно"),
):
    await crud.delete_user(session, user_id, actor, soft=not hard)
