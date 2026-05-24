from typing import TYPE_CHECKING, List

from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base
from .mixins import IntIdPkMixin, TimestampMixin

if TYPE_CHECKING:
    from .user import User
    from .product_variant import ProductVariant
    from .cart_item_modifiers_association import CartItemModifiersAssociation

class CartItem(IntIdPkMixin, TimestampMixin, Base):
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    product_variant_id: Mapped[int] = mapped_column(ForeignKey("product_variants.id"))
    quantity: Mapped[int]

    user: Mapped["User"] = relationship(back_populates="cart_items")
    product_variant: Mapped["ProductVariant"] = relationship(back_populates="cart_items")

    modifier_details: Mapped[List["CartItemModifiersAssociation"]] = relationship(back_populates="cart_items",
        cascade="all, delete-orphan",)

