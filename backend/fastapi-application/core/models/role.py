from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import String, Text, func, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.models.mixins import IntIdPkMixin
from .base import Base

if TYPE_CHECKING:
    from .role_and_permission import RoleAndPermission
    from .user_and_role import UserAndRole

class Role(IntIdPkMixin, Base):
    name: Mapped[str] = mapped_column(String(255), nullable=False, unique=True)
    description: Mapped[str] = mapped_column(Text)
    code: Mapped[str] = mapped_column(String(255), nullable=False, unique=True)
    # created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow, server_default=func.now())
    # created_by: Mapped[int] = mapped_column(
    #     ForeignKey('users.id', ondelete="SET NULL"), nullable=True
    # )
    # updated_at: Mapped[datetime] = mapped_column(nullable=True)
    # updated_by: Mapped[int] = mapped_column(
    #     ForeignKey('users.id', ondelete="SET NULL"), nullable=True,
    # )
    is_deleted: Mapped[bool] = mapped_column(default=False)


    # Поля для удаления и восстановления
    deleted_at: Mapped[datetime] = mapped_column(nullable=True)
    # deleted_by: Mapped[int] = mapped_column(
    #     ForeignKey('users.id', ondelete="SET NULL"), nullable=True,
    # )
    # restore_at: Mapped[datetime] = mapped_column(nullable=True)
    # restore_by: Mapped[int] = mapped_column(
    #     ForeignKey('users.id', ondelete="SET NULL"), nullable=True,
    # )

    permissions_details: Mapped[list["RoleAndPermission"]] = relationship(
        back_populates="roles",
        foreign_keys="RoleAndPermission.role_id",
        passive_deletes=True,
    )
    users_details: Mapped[list["UserAndRole"]] = relationship(
        back_populates="roles",
        foreign_keys="UserAndRole.role_id",
        # passive_deletes=True,
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "code": self.code,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "created_by": self.created_by,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "updated_by": self.updated_by,
            "is_active": self.is_active,
            "deleted_at": self.deleted_at.isoformat() if self.deleted_at else None,
            "deleted_by": self.deleted_by,
            "restore_at": self.restore_at.isoformat() if self.restore_at else None,
            "restore_by": self.restore_by
        }