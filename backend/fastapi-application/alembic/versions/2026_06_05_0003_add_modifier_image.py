"""add image_url to modifiers

Revision ID: 202606050003
Revises: 202606050002
Create Date: 2026-06-05
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "202606050003"
down_revision: Union[str, None] = "202606050002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "modifiers",
        sa.Column("image_url", sa.String(length=255), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("modifiers", "image_url")
