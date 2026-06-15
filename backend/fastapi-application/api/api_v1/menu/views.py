from typing import Annotated, List

from fastapi import APIRouter, Depends, Path, Query
from sqlalchemy.ext.asyncio import AsyncSession

from core.db_helper import db_helper

from . import crud
from .schemas import ProductScheme, FlatProductSchema

router = APIRouter()


@router.get(
    "/products",
    response_model=List[FlatProductSchema],
)
async def get_products(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.get_products(session)


@router.get(
    "/product/{product_id}",
    response_model=FlatProductSchema,
)
async def get_product(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    product_id: Annotated[int, Path],
    catalog_only: Annotated[
        bool,
        Query(
            description="True — только доступные к продаже позиции; False — для чеков/истории заказов",
        ),
    ] = True,
):
    return await crud.get_product_by_id(
        session=session,
        product_id=product_id,
        catalog_only=catalog_only,
    )
