from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict


class CartItemBase(BaseModel):
    """Базовая схема для элемента корзины"""

    food_id: int
    quantity: int = Field(gt=0, description="Количество товара")


class CartItemCreate(CartItemBase):
    """Схема для создания элемента корзины"""

    pass


class CartItemUpdate(BaseModel):
    """Схема для обновления элемента корзины"""

    quantity: int = Field(description="Новое количество товара")


class CartItemRead(CartItemBase):
    """Схема для чтения элемента корзины"""

    model_config = ConfigDict(from_attributes=True)

    unit_price: float
    total_price: float
    food_name: str
    food_description: Optional[str] = None
    food_image_url: Optional[str] = None

    # class Config:
    #     orm_mode = True


class CartBase(BaseModel):
    """Базовая схема для корзины"""

    user_id: int


class CartCreate(CartBase):
    """Схема для создания корзины"""

    items: Optional[List[CartItemCreate]] = []


class CartUpdate(BaseModel):
    """Схема для обновления корзины"""

    items: List[CartItemUpdate]


class CartItemOperation(BaseModel):
    """Схема для операций с отдельным товаром в корзине"""

    food_id: int
    quantity: int = Field(description="Количество товара (0 для удаления)")


class CartRead(CartBase):
    """Схема для чтения корзины"""

    id: int
    items: List[CartItemRead] = []
    total_amount: float
    items_count: int
    # created_at: datetime
    # updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class CartSummary(BaseModel):
    """Схема для сводной информации о корзине"""

    total_amount: float
    items_count: int
    unique_items: int
