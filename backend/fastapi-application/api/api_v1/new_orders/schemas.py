# Файл: schemas.py
# Описание: Схемы для создания и просмотра заказов клиентом.

from pydantic import BaseModel, ConfigDict
from typing import List, Optional
from datetime import datetime

# ===================================================================
# 1. СХЕМА ДЛЯ ЗАПРОСА (То, что Flutter шлет на сервер)
# ===================================================================


class OrderCreateRequest(BaseModel):
    """
    Данные, которые клиент вводит на странице оформления заказа.
    Содержимое заказа мы берем из серверной корзины пользователя.
    """

    customer_name: str
    customer_phone: str
    comment: Optional[str] = None


# ===================================================================
# 2. СХЕМЫ ДЛЯ ОТВЕТА (То, что сервер отдает Flutter'у)
# ===================================================================

# --- Вспомогательные, вложенные схемы для детализации ответа ---


class ProductInfo(BaseModel):
    """Краткая информация о базовом продукте (название, ID)."""

    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str


class OrderItemProductVariantResponse(BaseModel):
    """Краткая информация о варианте продукта в заказе."""

    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    product: ProductInfo


class OrderItemResponse(BaseModel):
    """Информация об одной позиции в заказе (строка в чеке)."""

    model_config = ConfigDict(from_attributes=True)
    id: int
    quantity: int
    price_per_unit: int  # Цена за 1 шт товара с добавками на момент заказа
    product_variant: OrderItemProductVariantResponse


class PaymentResponse(BaseModel):
    """Информация о платеже, связанном с заказом."""

    model_config = ConfigDict(from_attributes=True)
    status: str  # e.g., "PENDING" или "SUCCESSFUL"
    payment_system: Optional[str]  # e.g., "Post-payment"


class OrderStatusHistoryResponse(BaseModel):
    """Информация об одном изменении статуса в истории заказа."""

    model_config = ConfigDict(from_attributes=True)
    status: str  # e.g., "AWAITING_CONFIRMATION"
    created_at: datetime


# --- Основная, финальная схема для ответа ---


class OrderResponse(BaseModel):
    """Полная, детализированная информация о заказе."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    order_number: str
    status: str
    total_price: int
    created_at: datetime
    customer_name: str
    customer_phone: str
    comment: Optional[str]

    # Вложенные объекты, которые дают полную картину
    items: List[OrderItemResponse]
    payment: Optional[PaymentResponse]
    status_history: List[OrderStatusHistoryResponse]


class OrderStatusUpdateRequest(BaseModel):
    """
    Схема для запроса на изменение статуса заказа.
    Оператор передает новое значение статуса в виде строки.
    """

    status: str  # Например, "COOKING", "READY_FOR_PICKUP" и т.д.


# --- Ответ (Response) ---


class OrderSummaryResponse(BaseModel):
    """
    Краткая, сводная информация о заказе для отображения в списке.
    Это делает API быстрым и не перегружает фронтенд лишними данными.
    """

    model_config = ConfigDict(from_attributes=True)

    id: int
    order_number: str
    status: str
    total_price: int
    created_at: datetime
    customer_name: str
