from datetime import datetime
from typing import List

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.models import Promotion
from .schemas import PromotionCreate, PromotionUpdate


async def get_promotion(session: AsyncSession, promo_id: int) -> Promotion:
    promo = await session.get(Promotion, promo_id)
    if not promo:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Акция с ID {promo_id} не найдена.",
        )
    return promo


async def list_promotions(session: AsyncSession) -> List[Promotion]:
    result = await session.scalars(select(Promotion).order_by(Promotion.id))
    return list(result.all())


def _is_active_now(promo: Promotion, now: datetime) -> bool:
    if not promo.is_active:
        return False
    today = now.date()
    if promo.start_date and today < promo.start_date:
        return False
    if promo.end_date and today > promo.end_date:
        return False
    if promo.days_of_week:
        try:
            allowed = {int(x) for x in promo.days_of_week.split(",") if x != ""}
            if allowed and now.weekday() not in allowed:
                return False
        except ValueError:
            pass
    if promo.start_time and promo.end_time:
        current = now.strftime("%H:%M")
        if not (promo.start_time <= current <= promo.end_time):
            return False
    return True


async def list_active_promotions(session: AsyncSession) -> List[Promotion]:
    """Акции, применимые ПРЯМО СЕЙЧАС (для расчёта скидки): учитывают
    дату/время/дни недели."""
    now = datetime.now()
    return [p for p in await list_promotions(session) if _is_active_now(p, now)]


async def list_display_promotions(session: AsyncSession) -> List[Promotion]:
    """#11: акции для ВИТРИНЫ меню — все включённые и не истёкшие по дате.

    Условия по времени/дням недели показываются текстом на карточке, но не
    скрывают акцию из списка (иначе клиент её вообще не увидит)."""
    today = datetime.now().date()
    result = []
    for p in await list_promotions(session):
        if not p.is_active:
            continue
        if p.end_date and today > p.end_date:
            continue
        result.append(p)
    return result


async def create_promotion(
    session: AsyncSession, data: PromotionCreate
) -> Promotion:
    promo = Promotion(**data.model_dump())
    session.add(promo)
    await session.commit()
    await session.refresh(promo)
    return promo


async def update_promotion(
    session: AsyncSession, promo_id: int, data: PromotionUpdate
) -> Promotion:
    promo = await get_promotion(session, promo_id)
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(promo, key, value)
    await session.commit()
    await session.refresh(promo)
    return promo


async def delete_promotion(session: AsyncSession, promo_id: int) -> None:
    promo = await get_promotion(session, promo_id)
    await session.delete(promo)
    await session.commit()
