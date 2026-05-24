from typing import TYPE_CHECKING, List

from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.models import Base
from .mixins import IntIdPkMixin, SoftDeleteMixin
if TYPE_CHECKING:
    from .product import Product
    from .modifier_group import ModifierGroup
    from .combo_bundle import ComboBundle
    from .cart_item import CartItem


class ProductVariant(IntIdPkMixin, SoftDeleteMixin, Base):
    name: Mapped[str] = mapped_column(String(50))
    description: Mapped[str | None]
    price: Mapped[int]
    image_url: Mapped[str | None] = mapped_column(String(255))

    # --- Поля для отображения веса/объема в меню ---
    value: Mapped[int | None] # Числовое значение, e.g., 250,
    unit: Mapped[str | None] = mapped_column(String(30)) # Единица измерения, e.g., "мл", "гр", "шт"

    # Уникальный код товара / артикул
    sku: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    is_available: Mapped[bool] = mapped_column(default=True)
    is_combo: Mapped[bool] = mapped_column(default=False)

    product_id: Mapped[int] = mapped_column(ForeignKey("products.id", ondelete="CASCADE"))

    product: Mapped["Product"] = relationship(back_populates="variants")
    modifier_groups: Mapped[List["ModifierGroup"]] = relationship(
        secondary="modifier_group_associations", back_populates="product_variants"
    )
    # created_at: Mapped[datetime] = mapped_column(
    #     default=datetime.utcnow, server_default=func.now()
    # )
    # updated_at: Mapped[datetime] = mapped_column(
    #     default=datetime.utcnow, server_default=func.now()
    # )

    combo_contents: Mapped[List["ComboBundle"]] = relationship(
        "ComboBundle",
        foreign_keys="[ComboBundle.combo_variant_id]", # Явно указываем внешний ключ
        back_populates="combo_variant",
        cascade="all, delete-orphan" # Если удаляем комбо, удаляем и его состав
    )

    cart_items: Mapped[List["CartItem"]] = relationship(back_populates="product_variant")