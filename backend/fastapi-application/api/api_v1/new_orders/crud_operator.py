# Файл: operator/crud.py

from typing import List, Optional

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload, joinedload

# --- Импортируем все необходимые модели и схемы ---
from core.models import (
    Order,
    OrderItem,
    OrderStatusEnum,
    OrderStatusHistory,
    Payment,
)
from core.models import ProductVariant, Product

# ===================================================================
# 1. ЛОГИКА ДЛЯ ПОЛУЧЕНИЯ СПИСКА ЗАКАЗОВ (ДЛЯ ДАШБОРДА)
# ===================================================================

async def get_orders_by_status(
        session: AsyncSession,
        status_str: Optional[str] = None
) -> List[Order]:
    """
    Получает список заказов. Если статус указан, фильтрует по нему.
    Если не указан, возвращает все "активные" (не завершенные и не отмененные).
    """
    query = select(Order)

    if status_str:
        # Если передан фильтр по статусу, пытаемся преобразовать строку в Enum
        try:
            status_enum = OrderStatusEnum(status_str)
            query = query.where(Order.status == status_enum)
        except ValueError:
            # Если передано некорректное значение статуса
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Некорректный статус: '{status_str}'. Допустимые значения: {[e.value for e in OrderStatusEnum]}"
            )
    else:
        # По умолчанию показываем все, что требует внимания
        query = query.where(
            Order.status.not_in([OrderStatusEnum.COMPLETED, OrderStatusEnum.CANCELLED])
        )

    # Сортируем: новые заказы сверху
    query = query.order_by(Order.created_at.desc())

    result = await session.execute(query)
    # Возвращаем ORM-модели. Роутер сам преобразует их в OrderSummaryResponse
    return list(result.scalars().all())

# ===================================================================
# 2. ЛОГИКА ДЛЯ ПОЛУЧЕНИЯ ДЕТАЛЕЙ ОДНОГО ЗАКАЗА
# ===================================================================

async def get_order_by_id(order_id: int, session: AsyncSession) -> Order:
    """
    Получает полную, детализированную информацию по одному заказу.
    Используется, когда оператор кликает на заказ в списке.
    """
    query = (
        select(Order)
        .where(Order.id == order_id)
        .options(
            # Явно загружаем все связанные данные для полного ответа
            selectinload(Order.items).selectinload(OrderItem.product_variant).joinedload(ProductVariant.product),
            selectinload(Order.payment),
            selectinload(Order.status_history)
        )
    )
    result = await session.execute(query)
    order = result.scalar_one_or_none()

    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Заказ с ID {order_id} не найден."
        )

    return order

# ===================================================================
# 3. ЛОГИКА ДЛЯ ИЗМЕНЕНИЯ СТАТУСА ЗАКАЗА (САМАЯ ВАЖНАЯ)
# ===================================================================

# Определяем "карту" допустимых переходов статусов
VALID_STATUS_TRANSITIONS = {
    OrderStatusEnum.AWAITING_CONFIRMATION: [OrderStatusEnum.COOKING, OrderStatusEnum.CANCELLED],
    OrderStatusEnum.COOKING: [OrderStatusEnum.READY_FOR_PICKUP, OrderStatusEnum.CANCELLED],
    OrderStatusEnum.READY_FOR_PICKUP: [OrderStatusEnum.COMPLETED],
    # Из завершенных и отмененных статусов выходить нельзя
    OrderStatusEnum.COMPLETED: [],
    OrderStatusEnum.CANCELLED: []
}


async def update_order_status(
        order_id: int,
        new_status_str: str,
        session: AsyncSession
) -> Order:
    """
    Обновляет статус заказа, проверяя корректность перехода
    и создавая запись в истории.
    """
    async with session.begin():
        # Шаг 1: Находим заказ в базе данных
        order = await session.get(Order, order_id)
        if not order:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Заказ с ID {order_id} не найден."
            )

        # Шаг 2: Преобразуем строку статуса в Enum и валидируем
        try:
            new_status_enum = OrderStatusEnum(new_status_str)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Некорректный статус: '{new_status_str}'."
            )

        # Шаг 3: Проверяем бизнес-логику перехода статусов
        current_status = order.status
        allowed_transitions = VALID_STATUS_TRANSITIONS.get(current_status, [])

        if new_status_enum not in allowed_transitions:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Недопустимый переход из статуса '{current_status.value}' в '{new_status_enum.value}'."
            )

        # Шаг 4: Если все проверки пройдены, обновляем данные
        order.status = new_status_enum

        # Создаем новую запись в истории
        history_record = OrderStatusHistory(
            order_id=order.id,
            status=new_status_enum
        )
        session.add(history_record)

    # Транзакция успешно завершена

    # В будущем здесь будет отправка уведомления клиенту через WebSocket
    # websocket_manager.send_to_user(order.user_id, {"event": "STATUS_UPDATE", ...})

    # Возвращаем полный и обновленный объект заказа
    return await get_order_by_id(order_id=order_id, session=session)