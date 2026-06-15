from pydantic import BaseModel, ConfigDict
from typing import List, Optional


class CartItemAdminResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    product_variant_id: int
    quantity: int
    product_name: str
    variant_name: str
    price_per_unit: int
    subtotal: int


class CartAdminResponse(BaseModel):
    user_id: int
    items: List[CartItemAdminResponse]
    total_price: int
