from typing import List, Optional
from pydantic import BaseModel, ConfigDict

from api.admin.menu.category.category_schemas import CategoryResponse






class ProductVariantModifierGroupResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    is_deleted: bool


class ProductVariantResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    product_id: int
    name: str
    description: Optional[str]
    image_url: Optional[str]
    price: int
    sku: str
    value: Optional[float]
    unit: Optional[str]
    is_available: bool
    is_deleted: bool
    is_combo: bool
    modifier_groups: List[ProductVariantModifierGroupResponse] = []


class ProductVariantCreate(BaseModel):
    name: str
    description: Optional[str] = None
    image_url: Optional[str] = (
        "/static/images/placeholder_variant.png"
    )
    price: int
    sku: str
    value: Optional[float] = None
    unit: Optional[str] = None
    is_available: bool = True
    is_combo: bool = False


class ProductVariantUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    image_url: Optional[str] = None
    price: Optional[int] = None
    sku: Optional[str] = None
    value: Optional[float] = None
    unit: Optional[str] = None
    is_available: Optional[bool] = None
    is_combo: Optional[bool] = None


class ProductVariantDeleteResponse(BaseModel):
    success: bool
    message: str




class ProductCreate(BaseModel):
    category_id: int
    name: str
    description: Optional[str] = None
    image_url: str = "/static/images/placeholder.png"
    sort_order: int = 0


class ProductUpdate(BaseModel):
    category_id: Optional[int] = None
    name: Optional[str] = None
    description: Optional[str] = None
    image_url: Optional[str] = None
    sort_order: Optional[int] = None


class ProductResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    category: CategoryResponse
    name: str
    description: Optional[str]
    image_url: str
    sort_order: int
    is_deleted: bool
    variants: List[ProductVariantResponse]


class ProductDeleteResponse(BaseModel):
    success: bool
    message: str
