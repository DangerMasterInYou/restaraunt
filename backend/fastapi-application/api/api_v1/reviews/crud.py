from datetime import datetime
from typing import List

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import joinedload
from sqlalchemy.ext.asyncio import AsyncSession

from core.models.order_processing import Order, OrderStatusEnum, Review
from .schemas import ReviewCreate, ReviewRespond


async def create_review(
    user_id: int, data: ReviewCreate, session: AsyncSession
) -> Review:
    order = await session.get(Order, data.order_id)
    if order is None or order.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Заказ не найден"
        )
    if order.status != OrderStatusEnum.COMPLETED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Отзыв можно оставить только к завершённому заказу",
        )
    existing = await session.scalar(
        select(Review).where(
            Review.order_id == data.order_id, Review.user_id == user_id
        )
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Вы уже оставили отзыв к этому заказу",
        )
    review = Review(
        user_id=user_id,
        order_id=data.order_id,
        rating=data.rating,
        text=data.text,
    )
    session.add(review)
    await session.commit()
    await session.refresh(review)
    return review


async def get_my_reviews(user_id: int, session: AsyncSession) -> List[Review]:
    rows = await session.scalars(
        select(Review)
        .where(Review.user_id == user_id)
        .order_by(Review.created_at.desc())
    )
    return list(rows)


async def get_all_reviews(session: AsyncSession) -> List[Review]:
    rows = await session.scalars(
        select(Review)
        .options(joinedload(Review.order), joinedload(Review.user))
        .order_by(Review.created_at.desc())
    )
    return list(rows.unique().all())


async def respond_review(
    review_id: int, data: ReviewRespond, session: AsyncSession
) -> Review:
    review = await session.get(Review, review_id)
    if review is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Отзыв не найден"
        )
    review.response = data.response
    review.responded_at = datetime.utcnow()
    await session.commit()
    await session.refresh(review)
    return review


async def delete_review(review_id: int, session: AsyncSession) -> None:
    review = await session.get(Review, review_id)
    if review is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Отзыв не найден"
        )
    await session.delete(review)
    await session.commit()
