"""add promotions table

Revision ID: 202606050001
Revises: 202606020001
Create Date: 2026-06-05
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "202606050001"
down_revision: Union[str, None] = "202606020001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "promotions",
        sa.Column("id", sa.Integer(), primary_key=True, nullable=False),
        sa.Column("title", sa.String(length=120), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("discount_label", sa.String(length=60), nullable=True),
        sa.Column(
            "promo_type",
            sa.Enum("percent", "fixed", "bundle", name="promotiontype"),
            nullable=False,
            server_default="percent",
        ),
        sa.Column("discount_value", sa.Integer(), nullable=True),
        sa.Column("min_order_amount", sa.Integer(), nullable=True),
        sa.Column(
            "target_type",
            sa.Enum("all", "category", "product", name="promotiontargettype"),
            nullable=False,
            server_default="all",
        ),
        sa.Column("target_id", sa.Integer(), nullable=True),
        sa.Column("start_date", sa.Date(), nullable=True),
        sa.Column("end_date", sa.Date(), nullable=True),
        sa.Column("start_time", sa.String(length=5), nullable=True),
        sa.Column("end_time", sa.String(length=5), nullable=True),
        sa.Column("days_of_week", sa.String(length=20), nullable=True),
        sa.Column(
            "is_active",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("TRUE"),
        ),
        sa.Column(
            "created_at",
            sa.DateTime(),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )


def downgrade() -> None:
    op.drop_table("promotions")
    sa.Enum(name="promotiontype").drop(op.get_bind(), checkfirst=True)
    sa.Enum(name="promotiontargettype").drop(op.get_bind(), checkfirst=True)
