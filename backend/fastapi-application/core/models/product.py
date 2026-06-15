from typing import TYPE_CHECKING, List

from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.models import Base
from .mixins import IntIdPkMixin, SoftDeleteMixin
if TYPE_CHECKING:
    from .category import Category
    from .product_variant import ProductVariant


class Product(IntIdPkMixin, SoftDeleteMixin, Base):
    """Абстрактный продукт: 'Шаурма Классическая', 'Капучино'."""
    name: Mapped[str] = mapped_column(String(100), unique=True)
    description: Mapped[str] = mapped_column(Text)
    sort_order: Mapped[int] = mapped_column(default=0, index=True)
    image_url: Mapped[str] = mapped_column(String(255))

    category_id: Mapped[int] = mapped_column(ForeignKey("categories.id"))

    category: Mapped["Category"] = relationship(back_populates="products")
    variants: Mapped[List["ProductVariant"]] = relationship(
        back_populates="product", cascade="all, delete-orphan"
    )


