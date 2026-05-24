from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey, func, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.models import Base
from core.models.mixins.int_id_pk import IntIdPkMixin

if TYPE_CHECKING:
    from .cart import Cart
    from .product import Product


class CartFoodAssociation(IntIdPkMixin, Base):
    __table_args__ = (UniqueConstraint("cart_id", "product_id"),)

    count: Mapped[int] = mapped_column(default=0, server_default="0")
    unit_price: Mapped[int] = mapped_column(default=0, server_default="0")

    cart_id: Mapped[int] = mapped_column(ForeignKey("carts.id"))
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"))

    carts: Mapped["Cart"] = relationship(back_populates="products_details")
    # products: Mapped["Product"] = relationship(back_populates="carts_details")