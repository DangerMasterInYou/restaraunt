import enum
from datetime import date, datetime
from typing import TYPE_CHECKING, List

from pydantic import EmailStr
from sqlalchemy import String, func, text, Date, Boolean, Enum
from sqlalchemy.orm import mapped_column, Mapped, relationship


from . import Base
from core.models.mixins import IntIdPkMixin

if TYPE_CHECKING:
    from .cart_item import CartItem
    from .order_processing import Order, Favorite, Review

class UserRole(str, enum.Enum):
    client = "client"
    operator = "operator"
    admin = "admin"


class User(IntIdPkMixin, Base):
    email: Mapped[EmailStr] = mapped_column(String(254), unique=True)

    verification_code: Mapped[str] = mapped_column(String(40), nullable=True)
    verification_code_expires_at: Mapped[datetime] = mapped_column(nullable=True)

    password: Mapped[str] = mapped_column(String(100), nullable=True)
    first_name: Mapped[str] = mapped_column(String(100), nullable=True)
    last_name: Mapped[str] = mapped_column(String(100), nullable=True)
    birthday: Mapped[date] = mapped_column(Date, nullable=True)
    phone: Mapped[str] = mapped_column(String(20), nullable=True, unique=True)
    role: Mapped[UserRole] = mapped_column(Enum(UserRole), default=UserRole.client, server_default=text("client"))
    is_active: Mapped[bool] = mapped_column(
        Boolean, default=True, server_default=text("TRUE")
    )
    created_at: Mapped[datetime] = mapped_column(
        default=datetime.utcnow,
        server_default=func.now(),
    )
    cart_items: Mapped[List["CartItem"]] = relationship(back_populates="user")

    orders: Mapped[List["Order"]] = relationship(back_populates="user")
    favorites: Mapped[List["Favorite"]] = relationship(back_populates="user")
    reviews: Mapped[List["Review"]] = relationship(back_populates="user")

    def to_dict(self) -> dict:
        return {
            "email": self.email,

        }




