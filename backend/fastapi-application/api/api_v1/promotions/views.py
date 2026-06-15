from typing import Annotated, List

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.ext.asyncio import AsyncSession

from core.db_helper import db_helper
from api.api_v1.orders.views import require_admin
from . import crud
from .schemas import (
    PromotionCreate,
    PromotionUpdate,
    PromotionResponse,
    PromotionDeleteResponse,
)

public_router = APIRouter(prefix="/promotions", tags=["Promotions"])
admin_router = APIRouter(
    prefix="/admin/promotions",
    tags=["Admin: Promotions"],
    dependencies=[Depends(require_admin)],
)


@public_router.get("/active", response_model=List[PromotionResponse])
async def get_active_promotions(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """Список акций для витрины меню (включённые и не истёкшие). Условия по
    времени/дням показываются текстом; скидка применяется при их выполнении."""
    return await crud.list_display_promotions(session)


@admin_router.get("", response_model=List[PromotionResponse])
async def get_all_promotions(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.list_promotions(session)


@admin_router.post(
    "", response_model=PromotionResponse, status_code=status.HTTP_201_CREATED
)
async def create_promotion(
    data: PromotionCreate,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.create_promotion(session, data)


@admin_router.patch("/{promo_id}", response_model=PromotionResponse)
async def update_promotion(
    data: PromotionUpdate,
    promo_id: Annotated[int, Path],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.update_promotion(session, promo_id, data)


@admin_router.delete("/{promo_id}", response_model=PromotionDeleteResponse)
async def delete_promotion(
    promo_id: Annotated[int, Path],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    await crud.delete_promotion(session, promo_id)
    return PromotionDeleteResponse(success=True, message="Акция удалена.")
