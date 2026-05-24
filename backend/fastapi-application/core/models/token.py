from datetime import datetime

from sqlalchemy import String, ForeignKey, func
from sqlalchemy.orm import mapped_column, Mapped

from . import Base
from core.models.mixins import IntIdPkMixin


class Token(Base):
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    jti: Mapped[str] = mapped_column(String(255), primary_key=True)
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow, server_default=func.now())