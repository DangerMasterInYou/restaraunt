from datetime import datetime
from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload, joinedload
from core.models import (
    Order, OrderItem, OrderStatusEnum, Payment, PaymentStatusEnum, OrderStatusHistory,
    CartItem, CartItemModifiersAssociation, ProductVariant, Modifier
)
from .schemas import OrderCreateRequest, OrderItemUpdateRequest

# --- Вспомогательные функции ---
async def _get_order_by_id(order_id: int, session: AsyncSession, for_user_id: Optional[int] = None) -> Order:
    query = select(Order).where(Order.id == order_id)
    if for_user_id is not None:
        query = query.where(Order.user_id == for_user_id)
    query = query.options(
        selectinload(Order.items).selectinload(OrderItem.product_variant).joinedload(ProductVariant.product),
        selectinload(Order.payment),
        selectinload(Order.status_history)
    )
    result = await session.execute(query)
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Заказ не найден.")
    return order

async def _recalculate_total_price(order: Order, session: AsyncSession) -> int:
    total = 0
    for item in order.items:
        variant = await session.get(ProductVariant, item.product_variant_id)
        if variant:
            total += variant.price * item.quantity
    return total

# --- Основные CRUD ---
async def create_order_from_cart(
    user_id: int, order_data: OrderCreateRequest, session: AsyncSession
) -> Order:
    """Создаёт заказ из корзины пользователя и очищает корзину."""
    # Получаем корзину пользователя с модификаторами
    cart_items_query = (
        select(CartItem)
        .where(CartItem.user_id == user_id)
        .options(
            selectinload(CartItem.modifier_details).joinedload(CartItemModifiersAssociation.modifier),
            joinedload(CartItem.product_variant)
        )
    )
    cart_items = (await session.execute(cart_items_query)).scalars().all()
    if not cart_items:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Корзина пуста.")

    total_price = 0
    order_items = []
    for item in cart_items:
        base_price = item.product_variant.price
        modifiers_price = sum(mod.modifier.price_delta * mod.quantity for mod in item.modifier_details)
        price_per_unit = base_price + modifiers_price
        total_price += price_per_unit * item.quantity
        order_items.append(OrderItem(
            product_variant_id=item.product_variant.id,
            quantity=item.quantity,
            price_per_unit=price_per_unit,
        ))

    # Генерируем номер заказа
    order_number = f"ORD-{user_id}-{int(datetime.now().timestamp())}"

    new_order = Order(
        user_id=user_id,
        status=OrderStatusEnum.AWAITING_CONFIRMATION,
        customer_name=order_data.customer_name,
        customer_phone=order_data.customer_phone,
        comment=order_data.comment,
        total_price=total_price,
        order_number=order_number,
    )
    new_order.items = order_items
    new_order.payment = Payment(
        amount=total_price,
        status=PaymentStatusEnum.PENDING,
        payment_system=order_data.payment_method,
    )
    new_order.status_history = [OrderStatusHistory(status=OrderStatusEnum.AWAITING_CONFIRMATION)]

    session.add(new_order)

    # Очищаем корзину
    for item in cart_items:
        await session.delete(item)

    # ФИКС: явно сохраняем изменения в БД
    await session.commit()

    # Возвращаем заказ с подгруженными связями
    return await _get_order_by_id(new_order.id, session)

async def get_orders_for_user(user_id: int, session: AsyncSession) -> List[Order]:
    query = (
        select(Order)
        .where(Order.user_id == user_id)
        .options(
            selectinload(Order.items).selectinload(OrderItem.product_variant).joinedload(ProductVariant.product),
            selectinload(Order.payment),
            selectinload(Order.status_history)
        )
        .order_by(Order.created_at.desc())
    )
    result = await session.execute(query)
    return result.scalars().unique().all()

async def get_order_details_for_user(user_id: int, order_id: int, session: AsyncSession) -> Order:
    return await _get_order_by_id(order_id, session, for_user_id=user_id)

async def get_all_orders(session: AsyncSession, status_filter: Optional[str] = None) -> List[Order]:
    query = select(Order).options(
        selectinload(Order.items).selectinload(OrderItem.product_variant).joinedload(ProductVariant.product),
        selectinload(Order.payment),
        selectinload(Order.status_history)
    )
    if status_filter:
        query = query.where(Order.status == status_filter)
    query = query.order_by(Order.created_at.desc())
    result = await session.execute(query)
    return result.scalars().unique().all()

async def update_order_status(order_id: int, new_status_str: str, session: AsyncSession) -> Order:
    order = await _get_order_by_id(order_id, session)
    try:
        new_status = OrderStatusEnum(new_status_str)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Некорректный статус: {new_status_str}")

    if order.status == new_status:
        return order

    order.status = new_status
    order.status_history.append(OrderStatusHistory(status=new_status))
    await session.commit()
    await session.refresh(order)
    return order

async def update_order_items(order_id: int, items_data: List[OrderItemUpdateRequest], session: AsyncSession) -> Order:
    order = await _get_order_by_id(order_id, session)

    # Удаляем старые позиции
    for item in order.items:
        await session.delete(item)

    new_items = []
    total_price = 0
    for item_data in items_data:
        variant = await session.get(ProductVariant, item_data.product_variant_id)
        if not variant:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Вариант продукта ID {item_data.product_variant_id} не найден.")

        price_per_unit = variant.price
        if item_data.modifier_ids:
            modifiers = await session.execute(
                select(Modifier).where(Modifier.id.in_(item_data.modifier_ids))
            )
            modifiers = modifiers.scalars().all()
            price_per_unit += sum(m.price_delta for m in modifiers)

        total_price += price_per_unit * item_data.quantity
        new_items.append(OrderItem(
            order_id=order_id,
            product_variant_id=item_data.product_variant_id,
            quantity=item_data.quantity,
            price_per_unit=price_per_unit
        ))

    order.items = new_items
    order.total_price = total_price
    await session.commit()
    await session.refresh(order)
    return order

async def delete_order(order_id: int, session: AsyncSession) -> None:
    order = await _get_order_by_id(order_id, session)
    await session.delete(order)
    await session.commit()