# Файл: api/admin/menu/combo/router.py

from typing import Annotated, List
from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.ext.asyncio import AsyncSession

from core.db_helper import db_helper
from . import crud
from .schemas import (
    ComboItemCreate,
    ComboBundleResponse,
    ComboAssociationResponse,
    ComboItemResponse,
)

router = APIRouter()


@router.get(
    "/{combo_variant_id}/items",
    response_model=List[ComboItemResponse],
    summary="Получить состав комбо-набора",
)
async def get_combo_contents(
    combo_variant_id: Annotated[int, Path(description="ID комбо-варианта")],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Возвращает список всех товаров, входящих в указанный комбо-набор.
    """
    return await crud.get_combo_contents(combo_variant_id, session)


@router.post(
    "/{combo_variant_id}/items",
    response_model=ComboAssociationResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Добавить товар в комбо-набор",
)
async def add_item_to_combo(
    combo_variant_id: Annotated[int, Path(description="ID комбо-варианта")],
    item_data: ComboItemCreate,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Добавляет один товар (например, 'Картошка фри') в состав комбо.
    """
    await crud.add_item_to_combo(combo_variant_id, item_data, session)
    return {"success": True, "message": "Товар успешно добавлен в состав комбо."}


@router.delete(
    "/{combo_variant_id}/items/{included_variant_id}",
    response_model=ComboAssociationResponse,
    summary="Удалить товар из комбо-набора",
)
async def remove_item_from_combo(
    combo_variant_id: Annotated[int, Path(description="ID комбо-варианта")],
    included_variant_id: Annotated[
        int, Path(description="ID товара, который нужно убрать из комбо")
    ],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Удаляет один товар из состава комбо.
    """
    return await crud.remove_item_from_combo(
        combo_variant_id, included_variant_id, session
    )
