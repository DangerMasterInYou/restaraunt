"""widen orders.customer_phone to 32 (#2)

Revision ID: 202606120002
Revises: 202606120001
Create Date: 2026-06-12
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "202606120002"
down_revision: Union[str, None] = "202606120001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column(
        "orders",
        "customer_phone",
        type_=sa.String(length=32),
        existing_type=sa.String(length=20),
        existing_nullable=False,
    )


def downgrade() -> None:
    op.alter_column(
        "orders",
        "customer_phone",
        type_=sa.String(length=20),
        existing_type=sa.String(length=32),
        existing_nullable=False,
    )
