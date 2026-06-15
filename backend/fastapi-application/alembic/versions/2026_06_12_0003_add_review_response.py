"""add response/responded_at to reviews (#8)

Revision ID: 202606120003
Revises: 202606120002
Create Date: 2026-06-12
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "202606120003"
down_revision: Union[str, None] = "202606120002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("reviews", sa.Column("response", sa.Text(), nullable=True))
    op.add_column(
        "reviews",
        sa.Column("responded_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("reviews", "responded_at")
    op.drop_column("reviews", "response")
