"""add note to order_status_history and min_order_amount to promotions

Revision ID: 202606050002
Revises: 202606050001
Create Date: 2026-06-05
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "202606050002"
down_revision: Union[str, None] = "202606050001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "order_status_history",
        sa.Column("note", sa.Text(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("order_status_history", "note")
