"""backfill is_combo for combo components

Новая семантика флага is_combo на варианте продукта:
  - is_combo=true  -> вариант можно использовать как составляющую комбо;
  - is_combo=false -> вариант нельзя добавить в комбо / он не может в нём быть.
Сам комбо-набор определяется категорией «Комбо», а не флагом is_combo.

Эта миграция приводит существующие данные к новой семантике:
  1) у вариантов-контейнеров комбо (продукты категории «Комбо») снимаем is_combo;
  2) всем вариантам, уже входящим в состав комбо, выставляем is_combo=true.

Revision ID: 202606160001
Revises: 202606130001
Create Date: 2026-06-16
"""

from typing import Sequence, Union

from alembic import op


revision: str = "202606160001"
down_revision: Union[str, None] = "202606130001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Контейнеры комбо-наборов (категория «Комбо») составляющими не являются.
    op.execute(
        """
        UPDATE product_variants SET is_combo = false
        WHERE product_id IN (
            SELECT p.id FROM products p
            JOIN categories c ON c.id = p.category_id
            WHERE c.name = 'Комбо'
        )
        """
    )
    # 2. Все варианты, уже входящие в состав какого-либо комбо, помечаем как
    #    доступные для комбо (is_combo=true).
    op.execute(
        """
        UPDATE product_variants SET is_combo = true
        WHERE id IN (SELECT included_variant_id FROM combo_bundles)
        """
    )


def downgrade() -> None:
    # Возврат к старой семантике: контейнеры — is_combo=true, составляющие — false.
    op.execute(
        """
        UPDATE product_variants SET is_combo = false
        WHERE id IN (SELECT included_variant_id FROM combo_bundles)
        """
    )
    op.execute(
        """
        UPDATE product_variants SET is_combo = true
        WHERE product_id IN (
            SELECT p.id FROM products p
            JOIN categories c ON c.id = p.category_id
            WHERE c.name = 'Комбо'
        )
        """
    )
