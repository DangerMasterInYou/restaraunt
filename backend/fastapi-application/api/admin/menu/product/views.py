from typing import Annotated, List
from fastapi import APIRouter, status, Depends, Path, Body
from sqlalchemy.ext.asyncio import AsyncSession


from .schemas import (
    ProductCreate,
    ProductUpdate,
    ProductResponse,
    ProductDeleteResponse,
    ProductVariantCreate,
    ProductVariantUpdate,
    ProductVariantResponse,
    ProductVariantDeleteResponse,
)
from core.db_helper import db_helper
from . import crud

router = APIRouter()


@router.post("/products/reorder", status_code=status.HTTP_204_NO_CONTENT)
async def reorder_products(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    ids: List[int] = Body(..., embed=True),
):
    """#FE11: применяет порядок продуктов (drag-сортировка)."""
    await crud.reorder_products(session, ids)


@router.post(
    "/products",
    response_model=ProductResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_product(
    product: ProductCreate,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.create_product(session=session, product_data=product)


@router.get(
    "/products",
    response_model=list[ProductResponse],
)
async def get_products(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.get_products(session=session)


@router.get(
    "/products/{product_id}",
    response_model=ProductResponse,
)
async def get_product(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    product_id: Annotated[int, Path],
):
    return await crud.get_product(session=session, product_id=product_id)


@router.patch(
    "/products/{product_id}",
    response_model=ProductResponse,
)
async def update_product(
    product_update: ProductUpdate,
    product_id: Annotated[int, Path],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.update_product(
        product_id=product_id, product_update=product_update, session=session
    )


@router.delete(
    "/products/{product_id}/soft",
    response_model=ProductDeleteResponse,
)
async def soft_delete_product(
    product_id: Annotated[int, Path],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.soft_delete_product(
        product_id=product_id, session=session, deleted=True
    )


@router.post(
    "/products/{product_id}/restore",
    response_model=ProductDeleteResponse,
)
async def restore_product(
    product_id: Annotated[int, Path],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.soft_delete_product(
        product_id=product_id, session=session, deleted=False
    )


@router.delete(
    "/products/{product_id}/hard",
    response_model=ProductDeleteResponse,
)
async def hard_delete_product(
    product_id: Annotated[int, Path],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.hard_delete_product(product_id=product_id, session=session)




@router.get(
    "/variants",
    response_model=List[ProductVariantResponse],
    summary="Получить все варианты продуктов",
)
async def get_all_variants(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.get_all_variants(session=session)


@router.get(
    "/variants/{variant_id}",
    response_model=ProductVariantResponse,
    summary="Получить один вариант по ID",
)
async def get_variant(
    variant_id: Annotated[int, Path],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.get_variant(session=session, variant_id=variant_id)


@router.post(
    "/products/{product_id}/variants",
    response_model=ProductVariantResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Добавить вариант к продукту",
)
async def create_variant(
    product_id: Annotated[int, Path],
    variant_data: ProductVariantCreate,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.create_variant_for_product(
        product_id=product_id, variant_data=variant_data, session=session
    )


@router.patch(
    "/variants/{variant_id}",
    response_model=ProductVariantResponse,
    summary="Обновить конкретный вариант",
)
async def update_variant(
    variant_id: Annotated[int, Path],
    variant_update: ProductVariantUpdate,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.update_variant(
        variant_id=variant_id, variant_update=variant_update, session=session
    )


@router.delete(
    "/variants/{variant_id}/soft",
    response_model=ProductVariantDeleteResponse,
    summary="Мягкое удаление варианта",
)
async def soft_delete_variant(
    variant_id: Annotated[int, Path],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.soft_delete_variant(
        variant_id=variant_id, session=session, deleted=True
    )


@router.post(
    "/variants/{variant_id}/restore",
    response_model=ProductVariantDeleteResponse,
    summary="Восстановить мягко удаленный вариант",
)
async def restore_variant(
    variant_id: Annotated[int, Path],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.soft_delete_variant(
        variant_id=variant_id, session=session, deleted=False
    )


@router.delete(
    "/variants/{variant_id}/hard",
    response_model=ProductVariantDeleteResponse,
    summary="Безвозвратно удалить вариант (опасно)",
)
async def hard_delete_variant(
    variant_id: Annotated[int, Path],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.hard_delete_variant(variant_id=variant_id, session=session)
