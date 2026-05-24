# Файл: orders/router.py

from typing import Annotated, List

from fastapi import APIRouter, Depends, status, Path
from sqlalchemy.ext.asyncio import AsyncSession

from core.db_helper import db_helper
from .schemas import OrderCreateRequest, OrderResponse
from api.api_v1.auth_jwt.crud_validation import (
    get_current_user_id,
)  # Ваша зависимость для получения ID

from . import crud  # Предполагаем, что логика будет в crud.py

# Роутер для всех операций, связанных с заказами клиента
router = APIRouter(prefix="/orders", tags=["Orders"])


@router.post(
    "",
    response_model=OrderResponse,  # Теперь мы можем смело указать модель ответа
    status_code=status.HTTP_201_CREATED,
)
async def create_order(
    order_data: OrderCreateRequest,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_user_id)],
):
    """
    Создает заказ из корзины пользователя с постоплатой.

    Этот эндпоинт берет текущее содержимое серверной корзины пользователя,
    превращает его в постоянный заказ, очищает корзину и возвращает
    полную информацию о созданном заказе.
    """
    new_order = await crud.create_order_from_cart(
        user_id=user_id, order_data=order_data, session=session
    )
    return new_order


@router.get(
    "/my",
    response_model=List[OrderResponse],
)
async def get_my_orders(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_user_id)],
):
    """
    Получить список всех заказов (активных и завершенных) текущего пользователя.
    Используется для экрана "Мои заказы".
    """
    orders = await crud.get_orders_for_user(user_id=user_id, session=session)
    return orders


@router.get(
    "/{order_id}",
    response_model=OrderResponse,
)
async def get_my_order_details(
    order_id: Annotated[int, Path],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_user_id)],
):
    """
    Получить детали одного конкретного заказа.

    Бэкенд должен проверить, что запрашиваемый заказ действительно
    принадлежит текущему пользователю.
    """
    order = await crud.get_order_details_for_user(
        user_id=user_id, order_id=order_id, session=session
    )
    return order
