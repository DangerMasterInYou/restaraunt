# Файл: api/admin/menu/combo/schemas.py (Рекомендую создать новую папку и файл)

from typing import List
from pydantic import BaseModel, ConfigDict

# Импортируем схему ответа для варианта, чтобы показать, ЧТО именно лежит в комбо
from ..product.schemas import ProductVariantResponse


class ComboItemCreate(BaseModel):
    """Схема для добавления одного товара в комбо."""

    included_variant_id: int
    quantity: int = 1


class ComboItemResponse(BaseModel):
    """Схема для отображения одного товара в составе комбо."""

    model_config = ConfigDict(from_attributes=True)
    quantity: int
    # Показываем полную информацию о вложенном товаре
    included_variant: ProductVariantResponse


class ComboBundleResponse(BaseModel):
    """Схема для отображения полного состава комбо."""

    combo_variant_id: int
    items: List[ComboItemResponse]


class ComboAssociationResponse(BaseModel):
    success: bool
    message: str
