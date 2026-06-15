from typing import TYPE_CHECKING, List

from sqlalchemy import String
from sqlalchemy.orm import mapped_column, Mapped, relationship

from core.models import Base
from .mixins import IntIdPkMixin, SoftDeleteMixin

if TYPE_CHECKING:
    from .product import Product


class Category(IntIdPkMixin, SoftDeleteMixin, Base):
    __tablename__ = "categories"

    name: Mapped[str] = mapped_column(String(50), unique=True)
    sort_order: Mapped[int] = mapped_column(default=0, index=True)
    products: Mapped[List["Product"]] = relationship(back_populates="category")