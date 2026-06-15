from typing import Annotated, List

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from core.db_helper import db_helper
from core.models.order_processing import Review
from core.services.check_policy import (
    get_current_active_user_id,
    require_operator_or_admin,
    require_admin,
)
from . import crud
from .schemas import ReviewCreate, ReviewRespond, ReviewResponse

router = APIRouter(prefix="/reviews", tags=["Reviews"])
staff_router = APIRouter(prefix="/reviews", tags=["Reviews"])
admin_router = APIRouter(prefix="/admin/reviews", tags=["Admin Reviews"])


def _serialize(review: Review, *, with_order: bool = False) -> ReviewResponse:
    resp = ReviewResponse.model_validate(review)
    if with_order and review.order is not None:
        resp.order_number = review.order.order_number
        resp.customer_name = review.order.customer_name
        resp.customer_phone = review.order.customer_phone
    if with_order and review.user is not None:
        resp.customer_email = review.user.email
    return resp


@router.post("", response_model=ReviewResponse, status_code=status.HTTP_201_CREATED)
async def create_review(
    data: ReviewCreate,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_active_user_id)],
):
    review = await crud.create_review(user_id, data, session)
    return _serialize(review)


@router.get("/my", response_model=List[ReviewResponse])
async def my_reviews(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_active_user_id)],
):
    reviews = await crud.get_my_reviews(user_id, session)
    return [_serialize(r) for r in reviews]


@staff_router.get("/all", response_model=List[ReviewResponse])
async def all_reviews(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    _=Depends(require_operator_or_admin),
):
    reviews = await crud.get_all_reviews(session)
    return [_serialize(r, with_order=True) for r in reviews]


@admin_router.post("/{review_id}/respond", response_model=ReviewResponse)
async def respond_review(
    review_id: int,
    data: ReviewRespond,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    _=Depends(require_admin),
):
    review = await crud.respond_review(review_id, data, session)
    return _serialize(review)


@admin_router.delete("/{review_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_review(
    review_id: int,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    _=Depends(require_admin),
):
    await crud.delete_review(review_id, session)
