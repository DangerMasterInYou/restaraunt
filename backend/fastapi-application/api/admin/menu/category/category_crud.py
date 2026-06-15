from typing import List

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from fastapi import HTTPException, status

from core.models import Category
from api.admin.menu.category.category_schemas import (
    CategoryCreate,
    CategoryResponse,
    CategoryUpdate,
    CategoryDeleteResponse,
)


async def reorder_categories(session: AsyncSession, ids: List[int]) -> None:
    """#FE11: задаёт sort_order по порядку переданных id (drag-сортировка)."""
    for index, category_id in enumerate(ids):
        category = await session.get(Category, category_id)
        if category is not None:
            category.sort_order = index
    await session.commit()


async def create_category(
    category_data: CategoryCreate,
    session: AsyncSession,
) -> CategoryResponse:
    try:
        category_dict = category_data.model_dump()
        await check_for_an_existing_category(
            session=session,
            category=category_dict,
        )
        max_order = await session.scalar(select(func.max(Category.sort_order)))
        category_dict["sort_order"] = (max_order or 0) + 1
        category = Category(**category_dict)
        session.add(category)
        await session.commit()
        await session.refresh(category)

        return CategoryResponse.model_validate(category)
    except HTTPException:
        await session.rollback()
        raise

    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Internal server error when creating сategory: {e}",
        )


async def get_categories(
    session: AsyncSession,
) -> List[Category]:
    try:
        results = await session.scalars(
            select(Category)
            .order_by(Category.sort_order)
        )
        if not results:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Категория не найдена"
            )
        categories: list[Category] = list(results.all())

        return categories
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Internal server error when creating сategory: {e}",
        )


async def get_category(
    session: AsyncSession,
    category_id: int,
) -> Category:
    category: Category | None = await session.scalar(
        select(Category).where(Category.id == category_id)
    )
    if category is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Категория не найдена",
        )
    return category


async def check_for_an_existing_category(
    session: AsyncSession,
    category: dict,
    exclude_id: int | None = None,
) -> None:
    name_query = select(Category).where(Category.name == category["name"])
    if exclude_id:
        name_query = name_query.where(Category.id != exclude_id)
    existing_category_name = await session.scalar(name_query)
    if existing_category_name:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Категория c таким именем уже существует",
        )


async def update_category(
    category_id: int,
    category_update: CategoryUpdate,
    session: AsyncSession,
) -> CategoryResponse:
    try:
        category: Category = await get_category(
            session=session, category_id=category_id
        )
        if category.is_deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Категория мягко удалена",
            )

        category_dict = category_update.model_dump(exclude_unset=True)
        await check_for_an_existing_category(
            session=session,
            category=category_dict,
            exclude_id=category.id,
        )
        for name, value in category_dict.items():
            setattr(category, name, value)
        await session.commit()
        await session.refresh(category)
        return CategoryResponse.model_validate(category)
    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Internal server error when updating role: {e}",
        )


async def soft_delete_category(
    category_id: int,
    session: AsyncSession,
    deleted: bool,
) -> CategoryDeleteResponse:
    try:
        category: Category = await get_category(
            session=session, category_id=category_id
        )

        if category.is_deleted == deleted:
            if deleted:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Категория уже удалена",
                )
            else:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Категория уже восстановлена",
                )

        message: str
        if deleted:
            message = "Категория мягко удалена."
        else:
            message = "Категория восстановлена."

        category.is_deleted = deleted

        await session.commit()
        return CategoryDeleteResponse(success=True, message=message)

    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Internal server error when updating role: {e}",
        )


async def hard_delete_category(
    category_id: int,
    session: AsyncSession,
) -> CategoryDeleteResponse:
    try:
        category: Category = await get_category(
            session=session, category_id=category_id
        )
        await session.delete(category)
        await session.commit()
        return CategoryDeleteResponse(
            success=True, message="Категория удалена безвозвратно."
        )
    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Internal server error when updating role: {e}",
        )
