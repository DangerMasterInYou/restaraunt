"""add is_birthday to promotions (#8)

Revision ID: 202606120001
Revises: 202606050003
Create Date: 2026-06-12
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "202606120001"
down_revision: Union[str, None] = "202606050003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "promotions",
        sa.Column(
            "is_birthday",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("FALSE"),
        ),
    )


def downgrade() -> None:
    op.drop_column("promotions", "is_birthday")
