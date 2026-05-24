from typing import Annotated, List

from fastapi import APIRouter, status, Path, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from core.db_helper import db_helper
from .schemas import OrderCreate, OrderResponse

router = APIRouter()


@router.post(
    "/orders",
    response_model=OrderResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_order(
    order_data: OrderCreate,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    pass


@router.post(
    "/orders/{order_id}/pay",
    response_model=OrderResponse,
)
async def create_order_payment(
    order_id: Annotated[int, Path],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    pass


@router.get(
    "/orders/my}",
    response_model=List[OrderResponse],
)
async def get_my_orders(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    pass


@router.get(
    "/orders/{order_id}",
    response_model=OrderResponse,
)
async def get_my_order(
    order_id: Annotated[int, Path],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    pass
