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
    # created_at: str
    # updated_at: str


# в файле schemas.py

from pydantic import BaseModel
from typing import List, Optional


# Эти схемы описывают вложенные данные для модификаторов
class ModifierSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    price_delta: int


class ModifierGroupSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    is_required: bool
    is_multiselect: bool
    modifiers: List[ModifierSchema]


# А это основная схема для каждого элемента в итоговом списке
class FlatProductSchema(BaseModel):
    id: int  # ID варианта продукта
    name: str  # Склеенное имя
    description: Optional[str]
    image_url: Optional[str]
    category: str  # Название категории строкой
    price: int
    value: Optional[float]
    unit: Optional[str]
    sku: str
    is_available: bool
    modifier_groups: List[ModifierGroupSchema] = []
