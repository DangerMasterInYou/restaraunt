from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import String, Text, func, ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.models.mixins import IntIdPkMixin
from .base import Base

if TYPE_CHECKING:
    from .permission import Permission
    from .role import Role



class RoleAndPermission(IntIdPkMixin, Base):
    __tablename__ = 'roles_and_permissions'
    __table_args__ = (
        UniqueConstraint(
            'role_id',
            'permission_id',
            name="idx_unique_role_permission",
        ),
    )

    permission_id: Mapped[int] = mapped_column(
        ForeignKey('permissions.id', ondelete="CASCADE")
    )
    role_id: Mapped[int] = mapped_column(
        ForeignKey('roles.id', ondelete="CASCADE")
    )


    permissions: Mapped["Permission"] = relationship(
        back_populates="roles_details",
        foreign_keys=[permission_id],
        # passive_deletes=True,  # Удаляем эту строку
    )
    roles: Mapped["Role"] = relationship(
        back_populates="permissions_details",
        foreign_keys=[role_id],
        # passive_deletes=True,  # Удаляем эту строку
    )