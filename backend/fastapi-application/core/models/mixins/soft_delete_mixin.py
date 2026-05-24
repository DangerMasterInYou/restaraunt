from datetime import datetime


from sqlalchemy import Boolean, DateTime
from sqlalchemy.orm import mapped_column, Mapped


class SoftDeleteMixin:
    is_deleted: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default="false", index=True
    )
    # deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
