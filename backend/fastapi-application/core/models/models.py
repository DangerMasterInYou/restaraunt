from datetime import date, datetime
from typing import TYPE_CHECKING

from pydantic import EmailStr
from sqlalchemy import String, func, text, Date, Boolean, ForeignKey, UniqueConstraint
from sqlalchemy.orm import mapped_column, Mapped, relationship


from . import Base
from core.models.mixins import IntIdPkMixin

if TYPE_CHECKING:
    from .user import User
    from .user import User
    from .user import User
    from .user import User


class Address(IntIdPkMixin, Base):
    __tablename__ = "addresses"

    city: Mapped[str]
    postal_code: Mapped[str]
    street: Mapped[str]
    house: Mapped[str]
    entrance: Mapped[str]
    floor: Mapped[str]
    flat: Mapped[str]

    is_default: Mapped[bool] = mapped_column(default=False)

    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))



class Order(IntIdPkMixin, Base):
    order_number: Mapped[str] = mapped_column(unique=True)
    total_amount: Mapped[int]
    delivery_address: Mapped[str]
    payment_method: Mapped[str]
    paid: Mapped[bool]
    delivery_method: Mapped[str]
    delivery_cost: Mapped[int] = mapped_column(default=0)
    status: Mapped[str]
    comment: Mapped[str]
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow())
    updated_at: Mapped[datetime] = mapped_column(default=datetime.utcnow())




class OrderFoodAssociation(IntIdPkMixin, Base):
    __table_args__ = (UniqueConstraint("order_id", "product_id"),)

    count: Mapped[int] = mapped_column(default=0, server_default="0")
    unit_price: Mapped[int] = mapped_column(default=0, server_default="0")

    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id"))
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"))


class Payment(IntIdPkMixin, Base):
    payment_id: Mapped[str] = mapped_column(
        unique=True
    )
    amount: Mapped[int]
    status: Mapped[str]
    provider: Mapped[str]
    created_at: Mapped[datetime] = mapped_column(
        default=datetime.utcnow(), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        default=datetime.utcnow(), server_default=func.now()
    )

    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id"))