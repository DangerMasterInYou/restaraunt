from typing import List, Optional
from pydantic import BaseModel, ConfigDict

from api.admin.menu.category.category_schemas import CategoryResponse


# ===================================================================
# СХЕМЫ ДЛЯ УПРАВЛЕНИЯ ПРОДУКТАМИ
# ===================================================================


# --- Схемы для вариантов ---


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
    is_deleted: bool  # Добавляем флаг мягкого удаления
    is_combo: bool


class ProductVariantCreate(BaseModel):
    name: str
    description: Optional[str] = None
    image_url: Optional[str] = (
        "/static/images/placeholder_variant.png"  # Отдельная заглушка
    )
    price: int
    sku: str
    value: Optional[float] = None
    unit: Optional[str] = None
    is_available: bool = True
    is_combo: bool = False  # По умолчанию вариант - не комбо


class ProductVariantUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    image_url: Optional[str] = None
    price: Optional[int] = None
    sku: Optional[str] = None
    value: Optional[float] = None
    unit: Optional[str] = None
    is_available: Optional[bool] = None
    is_combo: Optional[bool] = None  # Позволяем сделать вариант комбо


class ProductVariantDeleteResponse(BaseModel):  # Эта схема уже подходит
    success: bool
    message: str


# --- Основные схемы для Продукта ---


# Схема для создания продукта (включая его варианты)
class ProductCreate(BaseModel):
    category_id: int
    name: str
    description: Optional[str] = None
    image_url: str = "/static/images/placeholder.png"  # URL-заглушка по умолчанию
    sort_order: int = 0
    # variants: List[ProductVariantCreate]  # Продукт создается сразу с вариантами


# Схема для обновления основной информации о продукте
class ProductUpdate(BaseModel):
    category_id: Optional[int] = None
    name: Optional[str] = None
    description: Optional[str] = None
    image_url: Optional[str] = None
    sort_order: Optional[int] = None


# Схема для ответа (возвращает полную информацию о продукте)
class ProductResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    category: CategoryResponse  # Вложенная схема для категории
    name: str
    description: Optional[str]
    image_url: str
    sort_order: int
    is_deleted: bool
    variants: List[ProductVariantResponse]  # Вложенный список вариантов


class ProductDeleteResponse(BaseModel):
    success: bool
    message: str
