from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import String, Text, func, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.models.mixins import IntIdPkMixin
from .base import Base

if TYPE_CHECKING:
    from .role_and_permission import RoleAndPermission

class Permission(IntIdPkMixin, Base):
    name: Mapped[str] = mapped_column(String(255), nullable=False, unique=True)
    description: Mapped[str] = mapped_column(Text)
    code: Mapped[str] = mapped_column(String(255), nullable=False, unique=True)

    is_deleted: Mapped[bool] = mapped_column(default=False)
    deleted_at: Mapped[datetime] = mapped_column(nullable=True)


    roles_details: Mapped[list["RoleAndPermission"]] = relationship(
        back_populates="permissions",
        foreign_keys="RoleAndPermission.permission_id",
        passive_deletes=True,
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "code": self.code,
            "is_deleted": self.is_deleted,
        }