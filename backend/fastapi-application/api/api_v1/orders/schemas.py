from pydantic import BaseModel, ConfigDict
from typing import List, Optional
from datetime import datetime

# --- Запросы от клиента ---
class OrderCreateRequest(BaseModel):
    """DTO для создания заказа (совместим с Flutter)."""
    customer_name: str
    customer_phone: str
    comment: Optional[str] = None
    payment_method: str  # "cash", "card", "online"

class OrderItemUpdateRequest(BaseModel):
    """DTO для изменения одной позиции в заказе."""
    product_variant_id: int
    quantity: int
    modifier_ids: Optional[List[int]] = None

class OrderStatusUpdateRequest(BaseModel):
    status: str  # AWAITING_CONFIRMATION, COOKING, READY_FOR_PICKUP, COMPLETED, CANCELLED

class OrderUpdateRequest(BaseModel):
    """Полное обновление заказа."""
    customer_name: Optional[str] = None
    customer_phone: Optional[str] = None
    comment: Optional[str] = None
    items: Optional[List[OrderItemUpdateRequest]] = None

# --- Ответы ---
class ProductInfo(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str

class OrderItemProductVariantResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    product: ProductInfo

class OrderItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    quantity: int
    price_per_unit: int
    product_variant: OrderItemProductVariantResponse

class PaymentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    status: str
    payment_system: Optional[str]

class OrderStatusHistoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    status: str
    created_at: datetime

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

class OrderSummaryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    order_number: str
    status: str
    total_price: int
    created_at: datetime
    customer_name: str