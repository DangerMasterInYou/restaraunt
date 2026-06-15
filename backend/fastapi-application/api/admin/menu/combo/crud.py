
from typing import List
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from fastapi import HTTPException, status

from core.models import ComboBundle, ProductVariant
from .schemas import ComboItemCreate
from ..product.crud import get_variant


async def add_item_to_combo(
    combo_variant_id: int,
    item_data: ComboItemCreate,
    session: AsyncSession,
) -> ComboBundle:
    """Добавляет один товар в состав комбо-набора."""
    try:
        combo_variant = await get_variant(session, combo_variant_id)
        if not combo_variant.is_combo:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST, "Этот продукт не является комбо-набором."
            )

        included_variant = await get_variant(session, item_data.included_variant_id)
        if included_variant.is_deleted or not included_variant.is_available:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                "Нельзя добавить недоступный или удаленный товар в комбо.",
            )

        if included_variant.is_combo:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                "Нельзя добавлять комбо-набор в другой комбо-набор.",
            )

        existing_item = await session.scalar(
            select(ComboBundle).where(
                ComboBundle.combo_variant_id == combo_variant_id,
                ComboBundle.included_variant_id == item_data.included_variant_id,
            )
        )
        if existing_item:
            raise HTTPException(
                status.HTTP_409_CONFLICT, "Этот товар уже добавлен в комбо."
            )

        new_combo_item = ComboBundle(
            combo_variant_id=combo_variant_id, **item_data.model_dump()
        )
        session.add(new_combo_item)
        await session.commit()
        await session.refresh(new_combo_item)
        return new_combo_item
    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            f"Ошибка добавления товара в комбо: {e}",
        )


async def remove_item_from_combo(
    combo_variant_id: int,
    included_variant_id: int,
    session: AsyncSession,
):
    """Удаляет один товар из состава комбо-набора."""
    try:
        item_to_delete = await session.scalar(
            select(ComboBundle).where(
                ComboBundle.combo_variant_id == combo_variant_id,
                ComboBundle.included_variant_id == included_variant_id,
            )
        )
        if not item_to_delete:
            raise HTTPException(
                status.HTTP_404_NOT_FOUND,
                "Такой товар в составе этого комбо не найден.",
            )

        await session.delete(item_to_delete)
        await session.commit()
        return {"success": True, "message": "Товар удален из состава комбо."}
    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            f"Ошибка удаления товара из комбо: {e}",
        )


async def get_combo_contents(
    combo_variant_id: int, session: AsyncSession
) -> List[ComboBundle]:
    """Получает полный состав комбо-набора."""
    combo_variant = await get_variant(session, combo_variant_id)
    if not combo_variant.is_combo:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, "Этот продукт не является комбо-набором."
        )

    stmt = (
        select(ComboBundle)
        .where(ComboBundle.combo_variant_id == combo_variant_id)
        .options(
            selectinload(ComboBundle.included_variant).selectinload(
                ProductVariant.modifier_groups
            )
        )
    )
    result = await session.scalars(stmt)
    return list(result.all())
