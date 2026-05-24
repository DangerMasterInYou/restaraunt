from typing import Annotated

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.ext.asyncio import AsyncSession

from core.db_helper import db_helper
from api.api_v1.auth_jwt.crud_validation import get_current_user_id

from .schemas import CartResponse, CartItemRequest, CartItemRequestUpdate
from . import service as cart_service

router = APIRouter()


@router.get("", response_model=CartResponse)
async def get_my_cart(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_user_id)],
):
    """Получить текущее состояние корзины пользователя."""
    return await cart_service.get_cart_for_user(user_id=user_id, session=session)


@router.post("/items", response_model=CartResponse, status_code=status.HTTP_201_CREATED)
async def add_item_to_cart(
    cart_item_data: CartItemRequest,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_user_id)],
):
    """Добавить товар с модификаторами в корзину."""
    return await cart_service.add_or_update_item(
        user_id=user_id, item_data=cart_item_data, session=session
    )


@router.patch("/items/{cart_item_id}", response_model=CartResponse)
async def update_cart_item_quantity(
    cart_item_update: CartItemRequestUpdate,
    cart_item_id: Annotated[int, Path],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_user_id)],
):
    """Изменить количество товара в конкретной строке корзины."""
    return await cart_service.update_item_quantity(
        user_id=user_id,
        cart_item_id=cart_item_id,
        quantity=cart_item_update.quantity,
        session=session,
    )


@router.delete("/items/{cart_item_id}", response_model=CartResponse)
async def remove_item_from_cart(
    cart_item_id: Annotated[int, Path],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_user_id)],
):
    """Удалить одну строку из корзины."""
    return await cart_service.remove_item(
        user_id=user_id, cart_item_id=cart_item_id, session=session
    )
