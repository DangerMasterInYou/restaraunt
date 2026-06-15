from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload, joinedload
from fastapi import HTTPException, status
from core.models import CartItem, ProductVariant, Product
from .schemas import CartAdminResponse, CartItemAdminResponse


async def get_cart_by_user(session: AsyncSession, user_id: int) -> CartAdminResponse:
    stmt = (
        select(CartItem)
        .where(CartItem.user_id == user_id)
        .options(
            joinedload(CartItem.product_variant).joinedload(ProductVariant.product)
        )
    )
    result = await session.execute(stmt)
    items = result.unique().scalars().all()

    total = 0
    response_items = []
    for item in items:
        price = item.product_variant.price
        subtotal = price * item.quantity
        total += subtotal
        response_items.append(
            CartItemAdminResponse(
                id=item.id,
                product_variant_id=item.product_variant_id,
                quantity=item.quantity,
                product_name=item.product_variant.product.name,
                variant_name=item.product_variant.name,
                price_per_unit=price,
                subtotal=subtotal,
            )
        )
    return CartAdminResponse(user_id=user_id, items=response_items, total_price=total)


async def clear_user_cart(session: AsyncSession, user_id: int) -> None:
    await session.execute(delete(CartItem).where(CartItem.user_id == user_id))
    await session.commit()


async def delete_cart_item(session: AsyncSession, cart_item_id: int) -> None:
    item = await session.get(CartItem, cart_item_id)
    if not item:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Позиция в корзине не найдена")
    await session.delete(item)
    await session.commit()
