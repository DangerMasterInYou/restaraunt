from typing import Annotated, List

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from core.db_helper import db_helper
from core.services.check_policy import get_current_active_user_id
from . import crud
from .schemas import (
    FavoriteGroupCreate,
    FavoriteGroupRename,
    FavoriteGroupResponse,
    FavoriteItemCreate,
)

router = APIRouter(prefix="/favorites/groups", tags=["Favorite Groups"])

UserId = Annotated[int, Depends(get_current_active_user_id)]
Session = Annotated[AsyncSession, Depends(db_helper.session_getter)]


@router.get("", response_model=List[FavoriteGroupResponse])
async def list_groups(session: Session, user_id: UserId):
    return await crud.list_groups(user_id, session)


@router.post(
    "", response_model=FavoriteGroupResponse, status_code=status.HTTP_201_CREATED
)
async def create_group(
    data: FavoriteGroupCreate, session: Session, user_id: UserId
):
    return await crud.create_group(user_id, data, session)


@router.patch("/{group_id}", response_model=FavoriteGroupResponse)
async def rename_group(
    group_id: int,
    data: FavoriteGroupRename,
    session: Session,
    user_id: UserId,
):
    return await crud.rename_group(user_id, group_id, data.name, session)


@router.delete("/{group_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_group(group_id: int, session: Session, user_id: UserId):
    await crud.delete_group(user_id, group_id, session)


@router.post("/{group_id}/items", response_model=FavoriteGroupResponse)
async def add_item(
    group_id: int,
    data: FavoriteItemCreate,
    session: Session,
    user_id: UserId,
):
    return await crud.add_item(user_id, group_id, data, session)


@router.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_item(item_id: int, session: Session, user_id: UserId):
    await crud.remove_item(user_id, item_id, session)


@router.post("/{group_id}/to-cart")
async def add_group_to_cart(group_id: int, session: Session, user_id: UserId):
    added = await crud.add_group_to_cart(user_id, group_id, session)
    return {"added": added}
