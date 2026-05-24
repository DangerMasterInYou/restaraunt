from typing import Annotated, List

from fastapi import APIRouter, status, Path, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from core.db_helper import db_helper
# from core.models import OrderStatusEnum
from .schemas import OrderCreate, OrderResponse, OrderStatusUpdateRequest

router = APIRouter(prefix="/operator", tags=["Operator"])


@router.get(
    "/orders",
    response_model=List[OrderResponse],
    status_code=status.HTTP_201_CREATED,
)
async def get_active_orders(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    order_status: OrderStatusEnum | None = None,
):
    pass


@router.get(
    "/orders/{order_id}",
    response_model=OrderResponse,
    status_code=status.HTTP_201_CREATED,
)
async def get_active_order(
    order_id: Annotated[int, Path],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    order_status: OrderStatusEnum | None = None,
):
    pass

@router.patch(
    "/orders/{order_id}/status",
    response_model=OrderResponse, )
async def update_active_order(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    order_status_data: OrderStatusUpdateRequest
):
    pass


@router.post(
    "/orders/{order_id}/cancel",
    response_model=OrderResponse, )
async def update_active_order(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    order_cancel_data: OrderStatusUpdateRequest
):
    pass

