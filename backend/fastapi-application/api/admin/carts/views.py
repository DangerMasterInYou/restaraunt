from typing import Annotated
from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.ext.asyncio import AsyncSession
from core.db_helper import db_helper
from api.api_v1.orders.views import require_admin
from . import crud
from .schemas import CartAdminResponse

router = APIRouter(
    prefix="/carts", tags=["Admin Carts"], dependencies=[Depends(require_admin)]
)


@router.get("/user/{user_id}", response_model=CartAdminResponse)
async def get_user_cart(
    user_id: int,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.get_cart_by_user(session, user_id)


@router.delete("/user/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def clear_user_cart(
    user_id: int,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    await crud.clear_user_cart(session, user_id)


@router.delete("/items/{cart_item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_cart_item(
    cart_item_id: int,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    await crud.delete_cart_item(session, cart_item_id)
