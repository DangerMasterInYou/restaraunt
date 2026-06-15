"""Расчёт скидок по активным акциям для корзины/заказа.

Каждая позиция (line item) описывается dict:
    {"category_id": int|None, "product_id": int|None, "subtotal": int}

Логика:
- target=all       → база = сумма всех позиций;
- target=category  → база = сумма позиций нужной категории;
- target=product   → база = сумма позиций нужного продукта;
- условие min_order_amount проверяется по ОБЩЕЙ сумме корзины;
- percent → скидка = база * X / 100; fixed → скидка = min(X, база).

Суммарная скидка не превышает общую сумму корзины.
"""

from datetime import date
from typing import List, Optional, Tuple

from sqlalchemy.ext.asyncio import AsyncSession

from core.models import PromotionType, PromotionTargetType
from .crud import list_active_promotions


async def compute_cart_discount(
    session: AsyncSession,
    line_items: List[dict],
    user_birthday: Optional[date] = None,
) -> Tuple[int, List[str]]:
    promos = await list_active_promotions(session)
    subtotal = sum(li["subtotal"] for li in line_items)
    if subtotal <= 0 or not promos:
        return 0, []

    today = date.today()
    is_birthday = (
        user_birthday is not None
        and user_birthday.month == today.month
        and user_birthday.day == today.day
    )

    total_discount = 0
    applied: List[str] = []

    for p in promos:
        if p.discount_value is None or p.discount_value <= 0:
            continue

        if getattr(p, "is_birthday", False) and not is_birthday:
            continue

        if p.target_type == PromotionTargetType.all:
            base = subtotal
        elif p.target_type == PromotionTargetType.category:
            base = sum(
                li["subtotal"]
                for li in line_items
                if li.get("category_id") == p.target_id
            )
        elif p.target_type == PromotionTargetType.product:
            base = sum(
                li["subtotal"]
                for li in line_items
                if li.get("product_id") == p.target_id
            )
        else:
            base = 0

        if base <= 0:
            continue

        gate_amount = subtotal if p.target_type == PromotionTargetType.all else base
        if p.min_order_amount and gate_amount < p.min_order_amount:
            continue

        if p.promo_type == PromotionType.percent:
            discount = base * p.discount_value // 100
        elif p.promo_type == PromotionType.fixed:
            discount = min(p.discount_value, base)
        else:
            discount = 0

        if discount > 0:
            total_discount += discount
            applied.append(p.discount_label or p.title)

    return min(total_discount, subtotal), applied
