from typing import TYPE_CHECKING, List

from sqlalchemy import String, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.models import Base
from .mixins import IntIdPkMixin, SoftDeleteMixin

if TYPE_CHECKING:
    from .modifier_group import ModifierGroup
    from .cart_item_modifiers_association import CartItemModifiersAssociation


class Modifier(IntIdPkMixin, SoftDeleteMixin, Base):
    """Конкретная опция: 'Сыр Чеддер', 'Без лука', 'Кисло-сладкий'."""
    name: Mapped[str] = mapped_column(String(50))
    price_delta: Mapped[int] = mapped_column(default=0)
    image_url: Mapped[str | None] = mapped_column(String(255), nullable=True)

    group_id: Mapped[int] = mapped_column(
        ForeignKey("modifier_groups.id", ondelete="CASCADE")
    )

    group: Mapped["ModifierGroup"] = relationship(back_populates="modifiers")

    cart_item_details: Mapped[List["CartItemModifiersAssociation"]] = relationship(back_populates="modifier")
