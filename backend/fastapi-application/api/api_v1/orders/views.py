from typing import Annotated, List, Optional
from fastapi import APIRouter, Depends, status, Path, Query, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from core.db_helper import db_helper
from api.api_v1.auth_jwt.crud_validation import get_current_token_payload, get_current_user_id
from core.models import User
from .schemas import (
    OrderCreateRequest, OrderResponse, OrderSummaryResponse,
    OrderStatusUpdateRequest, OrderItemUpdateRequest
)
from . import crud

router = APIRouter(prefix="/orders", tags=["Orders"])
operator_router = APIRouter(prefix="/operator/orders", tags=["Operator"])
admin_router = APIRouter(prefix="/admin/orders", tags=["Admin"])

# --- Вспомогательные зависимости для проверки ролей (без лишних запросов в БД) ---
def get_current_user_role(credentials: HTTPAuthorizationCredentials = Depends(HTTPBearer())) -> str:
    payload = get_current_token_payload(credentials)
    role = payload.get("role")
    if not role:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Роль не найдена в токене")
    return role

def require_operator_or_admin(role: str = Depends(get_current_user_role)) -> str:
    if role not in ("operator", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Требуется роль оператора или администратора")
    return role

def require_admin(role: str = Depends(get_current_user_role)) -> str:
    if role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Требуется роль администратора")
    return role

# --- Клиентские эндпоинты ---
@router.post("/create", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
async def create_order(
    order_data: OrderCreateRequest,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_user_id)],
):
    """Создаёт заказ из текущей корзины пользователя."""
    return await crud.create_order_from_cart(user_id, order_data, session)

@router.get("/my", response_model=List[OrderResponse])
async def get_my_orders(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_user_id)],
):
    """Список всех заказов текущего пользователя."""
    return await crud.get_orders_for_user(user_id, session)

@router.get("/{order_id}", response_model=OrderResponse)
async def get_my_order_details(
    order_id: int,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_user_id)],
):
    """Детали одного заказа (только свои)."""
    return await crud.get_order_details_for_user(user_id, order_id, session)

# --- Эндпоинты для оператора / администратора ---
@operator_router.get("", response_model=List[OrderResponse])
async def get_all_orders_for_operator(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    _: str = Depends(require_operator_or_admin),
    status_filter: Optional[str] = Query(None, description="Фильтр по статусу"),
):
    """Получить все заказы (оператор/админ)."""
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
    items_update: List[OrderItemUpdateRequest],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    _: str = Depends(require_operator_or_admin),
):
    """Полностью заменить состав заказа (новые позиции)."""
    return await crud.update_order_items(order_id, items_update, session)

# --- Эндпоинты только для администратора ---
@admin_router.delete("/{order_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_order_by_admin(
    order_id: int,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    _: str = Depends(require_admin),
):
    """Удалить заказ (безвозвратно)."""
    await crud.delete_order(order_id, session)

@admin_router.get("", response_model=List[OrderResponse])
async def get_all_orders_for_admin(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    _: str = Depends(require_admin),
    status_filter: Optional[str] = Query(None),
):
    """Получить все заказы (админ)."""
    return await crud.get_all_orders(session, status_filter)