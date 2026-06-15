from typing import List, Optional

from pydantic import BaseModel, ConfigDict

from api.admin.menu.modifier.schemas import ModifierResponse
from api.admin.menu.product.schemas import ProductVariantResponse


class AppliedModifierCreate(BaseModel):
    modifier_id: int
    quantity: int = 1


class CartItemRequest(BaseModel):
    product_variant_id: int
    quantity: int
    modifiers: List[AppliedModifierCreate] = []


class CartItemRequestUpdate(BaseModel):
    quantity: int


class AppliedModifierResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    quantity: int
    modifier: ModifierResponse


class CartItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    quantity: int
    product_name: Optional[str] = None
    product_variant: ProductVariantResponse
    applied_modifiers: List[AppliedModifierResponse]
    subtotal_price: int


class CartResponse(BaseModel):
    items: List[CartItemResponse]
    total_price: int
    subtotal_price: int = 0
    discount: int = 0
    applied_promotions: List[str] = []
