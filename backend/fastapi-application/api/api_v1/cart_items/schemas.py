# --- Схемы для Корзины (Request & Response) ---
from typing import List

from pydantic import BaseModel, ConfigDict

from api.admin.menu.modifier.schemas import ModifierResponse
from api.admin.menu.product.schemas import ProductVariantResponse


class AppliedModifierCreate(BaseModel):
    modifier_id: int
    quantity: int = 1


# ЗАПРОС: Добавление/обновление товара в корзине
class CartItemRequest(BaseModel):
    product_variant_id: int
    quantity: int  # Количество самого товара
    # Вместо списка ID теперь список объектов с количеством
    modifiers: List[AppliedModifierCreate] = []


class CartItemRequestUpdate(BaseModel):
    quantity: int


class AppliedModifierResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    quantity: int
    modifier: ModifierResponse  # Вложенная информация о самом модификаторе


# ОТВЕТ: Одна позиция в корзине
class CartItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int  # ID самой записи в корзине (не товара!)
    quantity: int
    product_variant: ProductVariantResponse  # Основной товар
    applied_modifiers: List[AppliedModifierResponse]  # <-- Изменение здесь
    subtotal_price: int  # Рассчитанная цена для этой строки (база + добавки) * кол-во


# ОТВЕТ: Вся корзина целиком
class CartResponse(BaseModel):
    items: List[CartItemResponse]
    total_price: int  # Итоговая цена всей корзины
