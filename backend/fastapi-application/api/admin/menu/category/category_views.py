from typing import Annotated, List

from fastapi import APIRouter, status, Depends, Path
from sqlalchemy.ext.asyncio import AsyncSession

from api.admin.menu.category.category_schemas import (
    CategoryDeleteResponse,
    CategoryResponse,
    CategoryCreate,
    CategoryUpdate,
)
from core.db_helper import db_helper

from . import category_crud

router = APIRouter()


@router.post(
    "/categories",
    response_model=CategoryResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_category(
    category: CategoryCreate,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await category_crud.create_category(session=session, category_data=category)


@router.get(
    "/categories",
    response_model=List[CategoryResponse],
)
async def get_categories(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await category_crud.get_categories(session=session)


@router.get(
    "/categories/{category_id}",
    response_model=CategoryResponse,
)
async def get_category_by_id(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    category_id: Annotated[int, Path],
):
    return await category_crud.get_category(session=session, category_id=category_id)


@router.patch(
    "/categories/{category_id}",
    response_model=CategoryResponse,
)
async def update_categories(
    category: CategoryUpdate,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    category_id: Annotated[int, Path],
):
    return await category_crud.update_category(
        category_id=category_id, category_update=category, session=session
    )


@router.delete(
    "/categories/{category_id}/soft",
    response_model=CategoryDeleteResponse,
)
async def soft_delete_category(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    category_id: Annotated[int, Path],
):
    return await category_crud.soft_delete_category(
        category_id=category_id, session=session, deleted=True
    )


@router.post(
    "/categories/{category_id}/restore",
    response_model=CategoryDeleteResponse,
)
async def restore_category(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    category_id: Annotated[int, Path],
):
    return await category_crud.soft_delete_category(
        category_id=category_id, session=session, deleted=False
    )


@router.delete(
    "/categories/{category_id}/hard",
    response_model=CategoryDeleteResponse,
)
async def hard_delete_category(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    category_id: Annotated[int, Path],
):
    return await category_crud.hard_delete_category(
        category_id=category_id, session=session
    )
