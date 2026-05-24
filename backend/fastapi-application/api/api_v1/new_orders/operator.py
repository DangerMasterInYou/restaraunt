# Файл: operator/router.py

from typing import Annotated, List, Optional

from fastapi import APIRouter, Depends, status, Path, Query
from sqlalchemy.ext.asyncio import AsyncSession

from core.db_helper import db_helper
# Ваши схемы
from .schemas import OrderSummaryResponse, OrderResponse, OrderStatusUpdateRequest
# Ваша зависимость для проверки роли "оператор"
# from ..auth_jwt.dependencies import require_operator_role

from . import crud_operator as operator_crud # Логика будет в отдельном файле

# Роутер для всех операций, доступных оператору
# `dependencies=[Depends(require_operator_role)]` применит защиту ко всем эндпоинтам в этом роутере
router = APIRouter(
    prefix="/operator/orders",
    tags=["Operator"],
    # dependencies=[Depends(require_operator_role)]
)

@router.get(
    "",
    response_model=List[OrderSummaryResponse],
)
async def get_active_orders(
        session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
        # Добавляем фильтрацию по статусу через query-параметры
        status_orders: Annotated[Optional[str], Query()] = None,
):
    """
    Получить список активных заказов.

    Основной эндпоинт для рабочего экрана оператора. Позволяет фильтровать
    заказы по статусу (например, ?status=AWAITING_CONFIRMATION).
    Если статус не указан, возвращает все НЕ завершенные и НЕ отмененные заказы.
    """
    orders = await operator_crud.get_orders_by_status(status_str=status_orders, session=session)
    return orders


@router.get(
    "/{order_id}",
    response_model=OrderResponse,
)
async def get_order_details_for_operator(
        order_id: Annotated[int, Path],
        session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Получить полную, детализированную информацию о конкретном заказе.
    Вызывается, когда оператор кликает на заказ в списке.
    """
    order = await operator_crud.get_order_by_id(order_id=order_id, session=session)
    return order


@router.patch(
    "/{order_id}/status",
    response_model=OrderResponse,
)
async def update_order_status(
        order_id: Annotated[int, Path],
        status_update: OrderStatusUpdateRequest,
        session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Изменить статус заказа.

    Это основная операция для оператора. Бэкенд должен проверить,
    что переход из текущего статуса в новый допустим.
    """
    updated_order = await operator_crud.update_order_status(
        order_id=order_id,
        new_status_str=status_update.status,
        session=session
    )
    return updated_order