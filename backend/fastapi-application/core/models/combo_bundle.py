from typing import TYPE_CHECKING

from sqlalchemy import UniqueConstraint, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.models import Base
from core.models.mixins import IntIdPkMixin

if TYPE_CHECKING:
    from .product_variant import ProductVariant


class ComboBundle(IntIdPkMixin, Base):
    """Описывает, из каких других товаров и в каком количестве состоит комбо."""

    # Составной первичный ключ
    __table_args__ = (
        UniqueConstraint(
            "combo_variant_id",
            "included_variant_id",
            name="idx_unique_combo_variant_included_variant",
        ),
    )

    combo_variant_id: Mapped[int] = mapped_column(ForeignKey("product_variants.id"))
    included_variant_id: Mapped[int] = mapped_column(ForeignKey("product_variants.id"))

    quantity: Mapped[int] = mapped_column(default=1)


    # 1. Связь "назад" к варианту, который является самим комбо-набором.
    combo_variant: Mapped["ProductVariant"] = relationship(
        "ProductVariant",
        foreign_keys=[combo_variant_id], # Указываем, какой FK использовать для этой связи
        back_populates="combo_contents"
    )

    # 2. Связь "вперед" к варианту, который является частью комбо.
    included_variant: Mapped["ProductVariant"] = relationship(
        "ProductVariant",
        foreign_keys=[included_variant_id] # Указываем другой FK для этой связи
    )

