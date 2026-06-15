from typing import Optional

from pydantic import BaseModel, ConfigDict


class ProductScheme(BaseModel):
    id: int
    name: str
    description: str
    price: int
    image_url: str
    weight_g: int | None = None
    volume_ml: int | None = None
    stock: int
    is_available: bool
    category: str



from pydantic import BaseModel
from typing import List, Optional


class ModifierSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    price_delta: int
    image_url: Optional[str] = None


class ModifierGroupSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    is_required: bool
    is_multiselect: bool
    modifiers: List[ModifierSchema]


class FlatProductSchema(BaseModel):
    id: int
    product_id: int
    name: str
    description: Optional[str]
    image_url: Optional[str]
    category: str
    price: int
    value: Optional[float]
    unit: Optional[str]
    sku: str
    is_available: bool
    modifier_groups: List[ModifierGroupSchema] = []
