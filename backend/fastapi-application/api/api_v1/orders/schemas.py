# Файл: schemas.py
from datetime import datetime

from pydantic import BaseModel, ConfigDict
from typing import List, Optional
from core.models import OrderStatusEnum  # Импортируем наш Enum

# ===================================================================
# СХЕМЫ ДЛЯ ЗАПРОСОВ (Request: то, что клиент шлет на сервер)
# ===================================================================


# Описание одной позиции в корзине при создании заказа
class OrderItemCreate(BaseModel):
    product_variant_id: int
    quantity: int


# Схема для создания заказа
class OrderCreate(BaseModel):
    customer_name: str
    customer_phone: str
    comment: Optional[str] = None
    items: List[OrderItemCreate]  # Содержимое корзины


# Схема для оператора для изменения статуса заказа
class OrderStatusUpdateRequest(BaseModel):
    status: OrderStatusEnum  # Новый статус, который нужно установить


# ===================================================================
# СХЕМЫ ДЛЯ ОТВЕТОВ (Response: то, что сервер отдает клиенту)
# ===================================================================


# Упрощенная информация о варианте для отображения в заказе
class OrderItemProductVariantResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str  # e.g. "Стандартная"
    # Информация о родительском продукте
    product: "ProductInfo"


class ProductInfo(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str  # e.g. "Шаурма Классическая"


# Ответ по одной позиции в заказе
class OrderItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    quantity: int
    price_per_unit: int  # "Замороженная" цена
    product_variant: OrderItemProductVariantResponse


# Ответ по платежу
class PaymentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    status: str
    payment_system: Optional[str]


# Ответ по истории статусов
class OrderStatusHistoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    status: str
    created_at: datetime


# Полная схема для ответа по одному заказу
class OrderResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    order_number: str
    status: str
    total_price: int
    created_at: datetime
    customer_name: str
    customer_phone: str
    comment: Optional[str]
    items: List[OrderItemResponse]
    payment: Optional[PaymentResponse]
    status_history: List[OrderStatusHistoryResponse]



