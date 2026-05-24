from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import String, Text, func, ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.models.mixins import IntIdPkMixin
from .base import Base

if TYPE_CHECKING:
    from .user import User
    from .role import Role

class UserAndRole(IntIdPkMixin, Base):
    __tablename__ = 'users_and_roles'
    __table_args__ = (
        UniqueConstraint(
            'user_id',
            'role_id',
            name="idx_unique_user_role",
        ),
    )

    user_id: Mapped[int] = mapped_column(
        ForeignKey('users.id', ondelete="CASCADE")
    )
    role_id: Mapped[int] = mapped_column(
        ForeignKey('roles.id', ondelete="CASCADE")
    )

    users: Mapped["User"] = relationship(
        back_populates="roles_details",
        foreign_keys=[user_id],
        passive_deletes=True,
    )
    roles: Mapped["Role"] = relationship(
        back_populates="users_details",
        foreign_keys=[role_id],
        passive_deletes=True,
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "role_id": self.role_id,
        }