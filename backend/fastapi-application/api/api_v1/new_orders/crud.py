# Файл: orders/crud.py

from datetime import datetime
from typing import List

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload, joinedload

# --- Импортируем все необходимые модели и схемы ---
from core.models import (
    Order,
    OrderItem,
    OrderStatusEnum,
    Payment,
    PaymentStatusEnum,
    OrderStatusHistory,
)
from core.models import CartItem, CartItemModifiersAssociation
from core.models import ProductVariant

from .schemas import OrderCreateRequest


# ===================================================================
# 1. ОСНОВНАЯ ФУНКЦИЯ: СОЗДАНИЕ ЗАКАЗА ИЗ КОРЗИНЫ
# ===================================================================


async def create_order_from_cart(
    user_id: int, order_data: OrderCreateRequest, session: AsyncSession
) -> Order:
    """
    Создает заказ на основе серверной корзины пользователя.
    Выполняется в одной атомарной транзакции.
    """

    # Шаг 1: Начинаем транзакцию. `begin_nested` - более безопасный вариант,
    # если эта функция вызывается из другой, уже имеющей транзакцию.
    async with session.begin_nested():
        # Шаг 2: Получаем все товары в корзине пользователя.
        # Загружаем все связанные данные, которые нам понадобятся для расчетов.
        cart_items_query = (
            select(CartItem)
            .where(CartItem.user_id == user_id)
            .options(
                selectinload(CartItem.modifier_details).joinedload(
                    CartItemModifiersAssociation.modifier
                ),
                joinedload(CartItem.product_variant),
            )
        )
        cart_items = (await session.execute(cart_items_query)).scalars().all()

        if not cart_items:
            # Если корзина пуста, нет смысла создавать заказ. Выдаем ошибку.
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Корзина пуста. Невозможно создать заказ.",
            )

        # Шаг 3: Рассчитываем итоговую стоимость и готовим позиции для заказа (OrderItems)
        total_price = 0
        order_items_to_create: List[OrderItem] = []

        for item in cart_items:
            # Считаем цену за 1 шт товара с учетом всех его добавок
            base_price = item.product_variant.price
            modifiers_price = sum(
                mod.modifier.price_delta * mod.quantity for mod in item.modifier_details
            )
            price_per_unit = base_price + modifiers_price

            # Добавляем стоимость этой строки (цена * кол-во) к общей сумме
            total_price += price_per_unit * item.quantity

            # Готовим объект OrderItem для добавления в заказ
            order_items_to_create.append(
                OrderItem(
                    product_variant_id=item.product_variant.id,
                    quantity=item.quantity,
                    price_per_unit=price_per_unit,  # "Замораживаем" цену
                )
            )

        # Шаг 4: Создаем основной объект заказа (Order)
        new_order = Order(
            user_id=user_id,
            status=OrderStatusEnum.AWAITING_CONFIRMATION,  # Начальный статус для постоплаты
            customer_name=order_data.customer_name,
            customer_phone=order_data.customer_phone,
            comment=order_data.comment,
            total_price=total_price,
            order_number=f"A-{user_id}-{int(datetime.now().timestamp())}",  # Пример генерации номера
        )

        # Шаг 5: Связываем заказ с его позициями, платежом и историей статуса
        new_order.items = order_items_to_create

        new_order.payment = Payment(
            amount=total_price,
            status=PaymentStatusEnum.PENDING,
            payment_system="Post-payment",  # Указываем тип оплаты
        )

        new_order.status_history = [
            OrderStatusHistory(status=OrderStatusEnum.AWAITING_CONFIRMATION)
        ]

        # Добавляем созданный заказ в сессию
        session.add(new_order)

        # Шаг 6: ОЧИЩАЕМ КОРЗИНУ ПОЛЬЗОВАТЕЛЯ
        for item in cart_items:
            await session.delete(item)

    # Транзакция автоматически коммитится здесь при выходе из `async with`

    # Шаг 7: Загружаем все данные для созданного заказа, чтобы вернуть полный ответ
    # Это важно, так как после коммита связи могут быть недоступны без пере-запроса
    final_order = await get_order_details_for_user(
        user_id=user_id,
        order_id=new_order.id,  # Используем ID только что созданного заказа
        session=session,
    )

    # В будущем здесь будет отправка уведомления оператору
    # websocket_manager.broadcast(...)

    return final_order


# ===================================================================
# 2. ФУНКЦИЯ ПОЛУЧЕНИЯ СПИСКА ЗАКАЗОВ
# ===================================================================


async def get_orders_for_user(user_id: int, session: AsyncSession) -> List[Order]:
    """Получает список всех заказов для пользователя."""
    query = (
        select(Order)
        .where(Order.user_id == user_id)
        .options(
            # Явно и заранее загружаем ВСЕ данные, которые нужны схеме OrderResponse
            selectinload(Order.items)
            .selectinload(OrderItem.product_variant)
            .joinedload(ProductVariant.product),
            selectinload(Order.payment),
            # --- ВОТ ИСПРАВЛЕНИЕ: Добавляем загрузку истории статусов ---
            selectinload(Order.status_history),
        )
        .order_by(Order.created_at.desc())  # Сортируем: новые заказы сверху
    )
    result = await session.execute(query)
    # scalars().all() теперь вернет полный "пакет" данных без необходимости
    # дополнительных ленивых запросов.
    return list(result.scalars().unique().all())


# ===================================================================
# 3. ФУНКЦИЯ ПОЛУЧЕНИЯ ДЕТАЛЕЙ ОДНОГО ЗАКАЗА
# ===================================================================


async def get_order_details_for_user(
    user_id: int, order_id: int, session: AsyncSession
) -> Order:
    """Получает полную, детализированную информацию по одному заказу."""
    query = (
        select(Order)
        .where(
            Order.id == order_id, Order.user_id == user_id  # <--- ПРОВЕРКА БЕЗОПАСНОСТИ
        )
        .options(
            # Здесь загружаем ВСЁ, так как это детальный просмотр
            selectinload(Order.items)
            .selectinload(OrderItem.product_variant)
            .joinedload(ProductVariant.product),
            selectinload(Order.payment),
            selectinload(Order.status_history),
        )
    )
    result = await session.execute(query)
    order = (
        result.scalar_one_or_none()
    )  # Используем, чтобы получить один результат или None

    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Заказ не найден."
        )

    return order
