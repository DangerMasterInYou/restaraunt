from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from core.models import Base


class ModifierGroupAssociation(Base):
    __tablename__ = "modifier_group_associations"

    product_variant_id: Mapped[int] = mapped_column(ForeignKey("product_variants.id"), primary_key=True)
    modifier_group_id: Mapped[int] = mapped_column(ForeignKey("modifier_groups.id"), primary_key=True)

    # __table_args__ = (
    #     UniqueConstraint(
    #     "product_variant_id",
    #     "modifier_group_id",
    #     name="idx_unique_product_variant_modifier_group",
    #     ),
    # )