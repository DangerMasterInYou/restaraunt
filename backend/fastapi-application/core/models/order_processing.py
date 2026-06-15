import enum
from datetime import datetime
from typing import List, Optional, TYPE_CHECKING

from sqlalchemy import (
    ForeignKey, String, Text, func, DateTime, Enum, JSON, text
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base
from .mixins import IntIdPkMixin

if TYPE_CHECKING:
    from .product_variant import ProductVariant
    from .user import User

class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())





class OrderStatusEnum(enum.Enum):
    AWAITING_CONFIRMATION = "Ожидает подтверждения"
    COOKING = "Готовится"
    READY_FOR_PICKUP = "Готов к выдаче"
    COMPLETED = "Завершен"
    CANCELLED = "Отменен"


class Order(IntIdPkMixin, TimestampMixin, Base):
    __tablename__ = "orders"

    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    user: Mapped["User"] = relationship(back_populates="orders")

    status: Mapped[OrderStatusEnum] = mapped_column(
        Enum(OrderStatusEnum), default=OrderStatusEnum.AWAITING_CONFIRMATION
    )

    customer_name: Mapped[str] = mapped_column(String(100))
    customer_phone: Mapped[str] = mapped_column(String(32))
    comment: Mapped[Optional[str]] = mapped_column(Text)

    total_price: Mapped[int]

    order_number: Mapped[str] = mapped_column(String(20), unique=True, index=True)

    items: Mapped[List["OrderItem"]] = relationship(back_populates="order", cascade="all, delete-orphan")
    status_history: Mapped[List["OrderStatusHistory"]] = relationship(back_populates="order", cascade="all, delete-orphan")
    payment: Mapped["Payment"] = relationship(back_populates="order", cascade="all, delete-orphan")


class OrderItem(IntIdPkMixin, Base):
    """Строка в чеке (заказе)"""
    __tablename__ = "order_items"

    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id", ondelete="CASCADE"))
    product_variant_id: Mapped[int] = mapped_column(
        ForeignKey("product_variants.id", ondelete="CASCADE")
    )

    order: Mapped["Order"] = relationship(back_populates="items")
    product_variant: Mapped["ProductVariant"] = relationship()

    quantity: Mapped[int]

    price_per_unit: Mapped[int]

    applied_modifiers: Mapped[List[dict]] = mapped_column(
        JSONB, default=list, server_default=text("'[]'::jsonb")
    )

class PaymentStatusEnum(enum.Enum):
    PENDING = "Ожидание"
    SUCCESSFUL = "Успешно"
    FAILED = "Ошибка"
    REFUNDED = "Возвращен"


class Payment(IntIdPkMixin, TimestampMixin, Base):
    __tablename__ = "payments"

    order_id: Mapped[int] = mapped_column(
        ForeignKey("orders.id", ondelete="CASCADE"), unique=True
    )
    order: Mapped["Order"] = relationship(back_populates="payment")

    amount: Mapped[int]
    status: Mapped[PaymentStatusEnum] = mapped_column(Enum(PaymentStatusEnum), default=PaymentStatusEnum.PENDING)

    payment_system: Mapped[Optional[str]] = mapped_column(String(50))
    transaction_id: Mapped[Optional[str]] = mapped_column(String(255), index=True)

class OrderStatusHistory(IntIdPkMixin, TimestampMixin, Base):
    __tablename__ = "order_status_history"

    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id", ondelete="CASCADE"))
    order: Mapped["Order"] = relationship(back_populates="status_history")

    status: Mapped[OrderStatusEnum] = mapped_column(Enum(OrderStatusEnum))
    note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

class Favorite(IntIdPkMixin, TimestampMixin, Base):
    """Связь 'многие-ко-многим' для избранных товаров"""
    __tablename__ = "favorites"

    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    product_variant_id: Mapped[int] = mapped_column(
        ForeignKey("product_variants.id", ondelete="CASCADE")
    )

    user: Mapped["User"] = relationship(back_populates="favorites")
    product_variant: Mapped["ProductVariant"] = relationship()


class Review(IntIdPkMixin, TimestampMixin, Base):
    __tablename__ = "reviews"

    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id", ondelete="CASCADE"))

    user: Mapped["User"] = relationship(back_populates="reviews")
    order: Mapped["Order"] = relationship()

    rating: Mapped[int]
    text: Mapped[Optional[str]] = mapped_column(Text)

    response: Mapped[Optional[str]] = mapped_column(Text)
    responded_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True)
    )


class FavoriteGroup(IntIdPkMixin, TimestampMixin, Base):
    """#5: именованная группа избранного клиента (например, «Праздник»).

    У разных клиентов имена и состав могут совпадать — это РАЗНЫЕ записи: каждая
    привязана к своему user_id и не объединяется с чужими.
    """
    __tablename__ = "favorite_groups"

    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE")
    )
    name: Mapped[str] = mapped_column(String(100))

    user: Mapped["User"] = relationship(back_populates="favorite_groups")
    items: Mapped[List["FavoriteGroupItem"]] = relationship(
        back_populates="group", cascade="all, delete-orphan"
    )


class FavoriteGroupItem(IntIdPkMixin, Base):
    """#5: позиция группы избранного — вариант продукта и выбранные модификаторы."""
    __tablename__ = "favorite_group_items"

    group_id: Mapped[int] = mapped_column(
        ForeignKey("favorite_groups.id", ondelete="CASCADE")
    )
    product_variant_id: Mapped[int] = mapped_column(
        ForeignKey("product_variants.id", ondelete="CASCADE")
    )
    quantity: Mapped[int] = mapped_column(default=1, server_default=text("1"))
    modifier_ids: Mapped[List[int]] = mapped_column(
        JSONB, default=list, server_default=text("'[]'::jsonb")
    )

    group: Mapped["FavoriteGroup"] = relationship(back_populates="items")
    product_variant: Mapped["ProductVariant"] = relationship()


