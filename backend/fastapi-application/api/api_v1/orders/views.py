from typing import Annotated, List, Optional
from fastapi import APIRouter, Depends, status, Path, Query, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from core.db_helper import db_helper
from core.services.check_policy import (  # noqa: F401
    get_current_user_role,
    require_operator_or_admin,
    require_admin,
    get_current_active_user_id,
)
from .schemas import (
    OrderCreateRequest,
    OrderResponse,
    OrderStatusUpdateRequest,
    OrderItemsReplaceRequest,
    OperatorOrderCreateRequest,
)
from . import crud

router = APIRouter(prefix="/orders", tags=["Orders"])
operator_router = APIRouter(prefix="/operator/orders", tags=["Operator"])
admin_router = APIRouter(prefix="/admin/orders", tags=["Admin"])

@router.post("/create", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
async def create_order(
    order_data: OrderCreateRequest,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_active_user_id)],
):
    """Создаёт заказ из корзины. Для онлайн-оплаты возвращает confirmation_url
    (атомарно: если ЮKassa упала — заказ не создаётся)."""
    order, confirmation_url = await crud.create_order_from_cart(
        user_id, order_data, session
    )
    data = OrderResponse.model_validate(order).model_dump()
    data["confirmation_url"] = confirmation_url
    return data

@router.get("/my", response_model=List[OrderResponse])
async def get_my_orders(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_active_user_id)],
):
    """Список всех заказов текущего пользователя."""
    return await crud.get_orders_for_user(user_id, session)

@router.get("/by-number/{order_number}", response_model=OrderResponse)
async def get_my_order_by_number(
    order_number: str,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_active_user_id)],
):
    """#3: детали заказа по order_number (для URL /orders/{order_number})."""
    return await crud.get_order_by_number_for_user(user_id, order_number, session)

@router.get("/{order_id}", response_model=OrderResponse)
async def get_my_order_details(
    order_id: int,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_active_user_id)],
):
    """Детали одного заказа (только свои)."""
    return await crud.get_order_details_for_user(user_id, order_id, session)

@operator_router.post(
    "/create",
    response_model=OrderResponse,
    status_code=status.HTTP_201_CREATED,
)
async def operator_create_order(
    data: OperatorOrderCreateRequest,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    operator=Depends(require_operator_or_admin),
):
    """#FE18: оператор создаёт заказ напрямую из позиций."""
    return await crud.create_order_direct(operator.id, data, session)


@operator_router.get("", response_model=List[OrderResponse])
async def get_all_orders_for_operator(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    _: str = Depends(require_operator_or_admin),
    status_filter: Optional[str] = Query(None, description="Фильтр по статусу"),
    active_only: bool = Query(True, description="Только активные (не архивные) заказы"),
):
    """Получить заказы (оператор/админ). Админ наследует права оператора."""
    if active_only and not status_filter:
        return await crud.get_active_orders(session)
    return await crud.get_all_orders(session, status_filter)

@operator_router.get("/{order_id}", response_model=OrderResponse)
async def get_order_details_for_operator(
    order_id: int,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    _: str = Depends(require_operator_or_admin),
):
    """Детали любого заказа."""
    return await crud._get_order_by_id(order_id, session)

@operator_router.patch("/{order_id}/status", response_model=OrderResponse)
async def update_order_status_by_operator(
    order_id: int,
    status_update: OrderStatusUpdateRequest,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    _: str = Depends(require_operator_or_admin),
):
    """Изменить статус заказа."""
    return await crud.update_order_status(order_id, status_update.status, session)

@operator_router.put("/{order_id}/items", response_model=OrderResponse)
async def update_order_items_by_operator(
    order_id: int,
    body: OrderItemsReplaceRequest,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    _: str = Depends(require_operator_or_admin),
):
    """Заменить состав активного заказа и при необходимости способ оплаты."""
    return await crud.update_order_items(
        order_id,
        body.items,
        session,
        payment_method=body.payment_method,
    )


@operator_router.patch("/{order_id}/birthday-discount", response_model=OrderResponse)
async def set_birthday_discount_by_operator(
    order_id: int,
    enabled: bool,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    _: str = Depends(require_operator_or_admin),
):
    """#5: вкл/выкл скидку в день рождения для неоплаченного заказа."""
    return await crud.set_birthday_discount(order_id, enabled, session)

@admin_router.delete("/{order_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_order_by_admin(
    order_id: int,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    _: str = Depends(require_admin),
):
    """Удалить заказ (безвозвратно)."""
    await crud.delete_order(order_id, session)

@admin_router.get("/active", response_model=List[OrderResponse])
async def get_active_orders_for_admin(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    _: str = Depends(require_operator_or_admin),
):
    """Активные заказы — те же права, что у оператора."""
    return await crud.get_active_orders(session)


@admin_router.patch("/{order_id}/status", response_model=OrderResponse)
async def update_order_status_by_admin(
    order_id: int,
    status_update: OrderStatusUpdateRequest,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    _: str = Depends(require_operator_or_admin),
):
    return await crud.update_order_status(order_id, status_update.status, session)


@admin_router.put("/{order_id}/items", response_model=OrderResponse)
async def update_order_items_by_admin(
    order_id: int,
    body: OrderItemsReplaceRequest,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    _: str = Depends(require_operator_or_admin),
):
    return await crud.update_order_items(
        order_id,
        body.items,
        session,
        payment_method=body.payment_method,
    )