from pydantic import BaseModel, ConfigDict
from typing import List, Optional
from datetime import datetime

class OrderCreateRequest(BaseModel):
    """DTO для создания заказа (совместим с Flutter)."""
    customer_name: str
    customer_phone: str
    comment: Optional[str] = None
    payment_method: str
    return_url: Optional[str] = None

class OrderItemUpdateRequest(BaseModel):
    """DTO для изменения одной позиции в заказе."""
    product_variant_id: int
    quantity: int
    modifier_ids: Optional[List[int]] = None

class OrderStatusUpdateRequest(BaseModel):
    status: str


class OrderItemsReplaceRequest(BaseModel):
    """Замена состава активного заказа и опционально способа оплаты."""
    items: List[OrderItemUpdateRequest]
    payment_method: Optional[str] = None


class OperatorOrderCreateRequest(BaseModel):
    """Создание заказа оператором (для клиента у стойки), #FE18."""
    customer_name: str
    customer_phone: str
    comment: Optional[str] = None
    payment_method: str = "cash"
    items: List[OrderItemUpdateRequest]

class OrderUpdateRequest(BaseModel):
    """Полное обновление заказа."""
    customer_name: Optional[str] = None
    customer_phone: Optional[str] = None
    comment: Optional[str] = None
    items: Optional[List[OrderItemUpdateRequest]] = None

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
    applied_modifiers: List["AppliedModifierResponse"] = []


class AppliedModifierResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    modifier_id: int
    name: str
    quantity: int
    price_delta: int

class PaymentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    status: str
    payment_system: Optional[str]
    amount: Optional[int] = None

class OrderStatusHistoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    status: str
    note: Optional[str] = None
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
    user_id: Optional[int] = None
    payment_method: Optional[str] = None
    updated_at: Optional[datetime] = None
    confirmation_url: Optional[str] = None

class OrderSummaryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    order_number: str
    status: str
    total_price: int
    created_at: datetime
    customer_name: str