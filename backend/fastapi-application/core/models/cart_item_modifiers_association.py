from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey
from sqlalchemy.orm import mapped_column, Mapped, relationship

from core.models import Base
from .mixins import IntIdPkMixin

if TYPE_CHECKING:
    from .cart_item import CartItem
    from .modifier import Modifier


class CartItemModifiersAssociation(IntIdPkMixin, Base):
    cart_item_id: Mapped[int] = mapped_column(ForeignKey("cart_items.id", ondelete="CASCADE",))
    modifier_id: Mapped[int] = mapped_column(ForeignKey("modifiers.id", ondelete="CASCADE",))

    quantity: Mapped[int] = mapped_column(default=1)

    cart_items: Mapped["CartItem"] = relationship(back_populates="modifier_details")
    modifier: Mapped["Modifier"] = relationship(back_populates="cart_item_details")

