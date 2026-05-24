from typing import TYPE_CHECKING
from typing import List

from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.models import Base
from .mixins import IntIdPkMixin, SoftDeleteMixin

if TYPE_CHECKING:
    from .modifier import Modifier
    from .product_variant import ProductVariant

class ModifierGroup(IntIdPkMixin, SoftDeleteMixin, Base):
    """Группа опций: 'Добавки', 'Выберите соус', 'Размер'."""
    name: Mapped[str] = mapped_column(String(50))
    is_required: Mapped[bool] = mapped_column(default=False)
    is_multiselect: Mapped[bool] = mapped_column(default=False)

    product_variants: Mapped[List["ProductVariant"]] = relationship(
        secondary="modifier_group_associations", back_populates="modifier_groups"
    )

    modifiers: Mapped[List["Modifier"]] = relationship(back_populates="group")
