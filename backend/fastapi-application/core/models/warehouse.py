import enum
from datetime import datetime
from typing import List, Optional, TYPE_CHECKING

from sqlalchemy import (
    ForeignKey, String, Text, func
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base
from .mixins import IntIdPkMixin

if TYPE_CHECKING:
    from .product_variant import ProductVariant
    from .modifier import Modifier

class Ingredient(IntIdPkMixin, Base):
    __tablename__ = "ingredients"
    name: Mapped[str] = mapped_column(String(100), unique=True)
    unit_of_measure: Mapped[str] = mapped_column(String(10))

class Recipe(Base):
    """Рецепт для основного товара."""
    __tablename__ = "recipes"
    product_variant_id: Mapped[int] = mapped_column(ForeignKey("product_variants.id"), primary_key=True)
    ingredient_id: Mapped[int] = mapped_column(ForeignKey("ingredients.id"), primary_key=True)
    quantity_used: Mapped[float]

    product_variant: Mapped["ProductVariant"] = relationship(back_populates="recipe_items")
    ingredient: Mapped["Ingredient"] = relationship()

class ModifierRecipe(Base):
    """Рецепт для модификатора (что списывать при его выборе)."""
    __tablename__ = "modifier_recipes"
    modifier_id: Mapped[int] = mapped_column(ForeignKey("modifiers.id"), primary_key=True)
    ingredient_id: Mapped[int] = mapped_column(ForeignKey("ingredients.id"), primary_key=True)
    quantity_used: Mapped[float]

    modifier: Mapped["Modifier"] = relationship(back_populates="recipe_items")
    ingredient: Mapped["Ingredient"] = relationship()



class TransactionType(enum.Enum):
    PURCHASE = "Приход"
    SALE = "Продажа"
    SPOILAGE = "Списание"
    ADJUSTMENT = "Корректировка"

class InventoryTransaction(IntIdPkMixin, Base):
    """Заголовок транзакции (HDR)."""
    __tablename__ = "inventory_transactions"
    timestamp: Mapped[datetime] = mapped_column(server_default=func.now())
    transaction_type: Mapped[TransactionType]
    notes: Mapped[Optional[str]] = mapped_column(Text)
    details: Mapped[List["InventoryTransactionDetail"]] = relationship(back_populates="transaction", cascade="all, delete-orphan")

class InventoryTransactionDetail(IntIdPkMixin, Base):
    """Детали транзакции (DTL)."""
    __tablename__ = "inventory_transaction_details"
    transaction_id: Mapped[int] = mapped_column(ForeignKey("inventory_transactions.id"))
    ingredient_id: Mapped[int] = mapped_column(ForeignKey("ingredients.id"))
    quantity: Mapped[float]

    transaction: Mapped["InventoryTransaction"] = relationship(back_populates="details")
    ingredient: Mapped["Ingredient"] = relationship()