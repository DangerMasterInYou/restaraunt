from typing import List

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload, subqueryload, selectinload
from fastapi import HTTPException, status

from core.models import Product, ProductVariant

from .schemas import (
    ProductCreate,
    ProductUpdate,
    ProductResponse,
    ProductDeleteResponse,
    ProductVariantCreate,  # Добавляем для типизации
    ProductVariantUpdate,
    ProductVariantDeleteResponse,
)
from ..category.category_crud import get_category

# ===================================================================
# CRUD-ФУНКЦИИ ДЛЯ ПРОДУКТОВ
# ===================================================================


async def get_product(session: AsyncSession, product_id: int) -> Product:
    """Вспомогательная функция для получения одного продукта со всеми связями."""
    product: Product | None = await session.get(
        Product,
        product_id,
        options=[joinedload(Product.category), subqueryload(Product.variants)],
    )
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Продукт с ID {product_id} не найден",
        )
    return product


async def check_for_an_existing_product(
    session: AsyncSession,
    product_name: str,
    exclude_id: int | None = None,
) -> None:
    """Проверка на уникальность имени продукта."""
    query = select(Product).where(Product.name == product_name)
    if exclude_id:
        query = query.where(Product.id != exclude_id)

    existing_product = await session.scalar(query)
    if existing_product:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Продукт с именем '{product_name}' уже существует",
        )


async def create_product(
    product_data: ProductCreate,
    session: AsyncSession,
) -> Product:
    try:
        # Проверяем, существует ли категория и не удалена ли она
        category = await get_category(
            session=session, category_id=product_data.category_id
        )
        if category.is_deleted:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Категория с ID {product_data.category_id} удалена и не может быть использована.",
            )

        # Проверяем уникальность имени нового продукта
        await check_for_an_existing_product(session, product_data.name)

        # if not product_data.variants:
        #     raise HTTPException(
        #         status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        #         detail="Продукт должен иметь хотя бы один вариант.",
        #     )

        # Создаем абстрактный продукт
        product_dict = product_data.model_dump(exclude={"variants"})
        new_product = Product(**product_dict)
        session.add(new_product)
        # await session.flush()  # Получаем ID для new_product
        #
        # # Создаем варианты для этого продукта
        # for variant_data in product_data.variants:
        #     variant_dict = variant_data.model_dump()
        #     variant_dict["product_id"] = new_product.id
        #     new_variant = ProductVariant(**variant_dict)
        #     session.add(new_variant)

        await session.commit()
        await session.refresh(new_product, ["category", "variants"])  # Обновляем связи
        return new_product

    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Внутренняя ошибка при создании продукта: {e}",
        )


async def get_products(session: AsyncSession) -> List[ProductResponse]:
    result = await session.scalars(
        select(Product)
        .options(joinedload(Product.category), selectinload(Product.variants))
        .order_by(Product.sort_order)
    )
    products: List[Product] = list(result.all())
    return products


async def update_product(
    product_id: int,
    product_update: ProductUpdate,
    session: AsyncSession,
) -> Product:
    try:
        product = await get_product(session, product_id)
        if product.is_deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Продукт мягко удален",
            )
        category = await get_category(
            session=session, category_id=product_update.category_id
        )
        if category.is_deleted:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Категория с ID {product_update.category_id} удалена и не может быть использована.",
            )
        update_data = product_update.model_dump(exclude_unset=True)

        if "name" in update_data:
            await check_for_an_existing_product(
                session, update_data["name"], exclude_id=product_id
            )

        for key, value in update_data.items():
            setattr(product, key, value)

        await session.commit()
        await session.refresh(product, ["category", "variants"])
        return product

    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Внутренняя ошибка при обновлении продукта: {e}",
        )


async def soft_delete_product(
    product_id: int,
    session: AsyncSession,
    deleted: bool,
) -> ProductDeleteResponse:
    try:
        product = await get_product(session, product_id)

        if product.is_deleted == deleted:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Продукт уже находится в состоянии 'deleted={deleted}'",
            )

        product.is_deleted = deleted
        message = "Продукт мягко удален." if deleted else "Продукт восстановлен."

        await session.commit()
        return ProductDeleteResponse(success=True, message=message)
    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Внутренняя ошибка: {e}",
        )


async def hard_delete_product(
    product_id: int,
    session: AsyncSession,
) -> ProductDeleteResponse:
    try:
        product = await get_product(session, product_id)
        await session.delete(product)
        await session.commit()
        return ProductDeleteResponse(
            success=True, message="Продукт удален безвозвратно."
        )
    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Внутренняя ошибка: {e}",
        )


# ===================================================================
# CRUD-ФУНКЦИИ ДЛЯ ВАРИАНТОВ ПРОДУКТОВ
# ===================================================================


async def get_all_variants(session: AsyncSession) -> List[ProductVariant]:
    """Получает список всех вариантов (включая мягко удаленные)."""
    result = await session.execute(select(ProductVariant).order_by(ProductVariant.id))
    return list(result.scalars().all())


async def get_variant(session: AsyncSession, variant_id: int) -> ProductVariant:
    """Вспомогательная функция для получения одного варианта."""
    variant: ProductVariant | None = await session.scalar(
        select(ProductVariant)
        .where(ProductVariant.id == variant_id)
        .options(selectinload(ProductVariant.modifier_groups))
    )

    if not variant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Вариант с ID {variant_id} не найден.",
        )
    return variant


async def check_for_an_existing_sku(
    session: AsyncSession,
    sku: str,
    exclude_id: int | None = None,
) -> None:
    """Проверка на уникальность SKU варианта."""
    query = select(ProductVariant).where(ProductVariant.sku == sku)
    if exclude_id:
        query = query.where(ProductVariant.id != exclude_id)

    existing_sku = await session.scalar(query)
    if existing_sku:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Вариант с SKU '{sku}' уже существует.",
        )


async def create_variant_for_product(
    product_id: int,
    variant_data: ProductVariantCreate,
    session: AsyncSession,
) -> ProductVariant:
    """Создает новый вариант для существующего продукта."""
    try:
        # Проверяем, что родительский продукт существует и не удален
        product = await get_product(session, product_id)
        if product.is_deleted:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Продукт с ID {product_id} удален и не может быть изменен.",
            )

        # Проверяем SKU на уникальность
        await check_for_an_existing_sku(session, variant_data.sku)

        # Создаем и добавляем новый вариант
        new_variant = ProductVariant(product_id=product_id, **variant_data.model_dump())
        session.add(new_variant)
        await session.commit()
        await session.refresh(new_variant)
        return new_variant

    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Внутренняя ошибка при создании варианта: {e}",
        )


async def update_variant(
    variant_id: int,
    variant_update: ProductVariantUpdate,
    session: AsyncSession,
) -> ProductVariant:
    """Обновляет информацию о конкретном варианте."""
    try:
        variant = await get_variant(session, variant_id)
        update_data = variant_update.model_dump(exclude_unset=True)

        if "sku" in update_data:
            await check_for_an_existing_sku(
                session, update_data["sku"], exclude_id=variant_id
            )

        for key, value in update_data.items():
            setattr(variant, key, value)

        await session.commit()
        await session.refresh(variant)
        return variant

    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Внутренняя ошибка при обновлении варианта: {e}",
        )


async def soft_delete_variant(
    variant_id: int,
    session: AsyncSession,
    deleted: bool,
) -> ProductVariantDeleteResponse:
    """Мягкое удаление или восстановление варианта."""
    try:
        variant = await get_variant(session, variant_id)

        if variant.is_deleted == deleted:
            state = "удален" if deleted else "восстановлен"
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Вариант уже находится в состоянии '{state}'",
            )

        # --- Проверка на последний вариант ---
        if deleted:  # Проверяем только при удалении
            count_stmt = select(func.count(ProductVariant.id)).where(
                ProductVariant.product_id == variant.product_id,
                ProductVariant.is_deleted == False,  # Считаем только активные варианты
            )
            active_variants_count = await session.scalar(count_stmt)
            if active_variants_count <= 1:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Нельзя удалить последний активный вариант продукта.",
                )
        # ------------------------------------

        variant.is_deleted = deleted
        message = "Вариант мягко удален." if deleted else "Вариант восстановлен."

        await session.commit()
        return ProductVariantDeleteResponse(success=True, message=message)

    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(status_code=500, detail=f"Внутренняя ошибка: {e}")


async def hard_delete_variant(
    variant_id: int,
    session: AsyncSession,
) -> ProductVariantDeleteResponse:
    """Безвозвратно удаляет вариант с проверкой, что он не последний."""
    try:
        variant_to_delete = await get_variant(session, variant_id)

        # --- КЛЮЧЕВАЯ БИЗНЕС-ЛОГИКА ---
        # Проверяем, не является ли этот вариант последним для продукта
        count_stmt = select(func.count(ProductVariant.id)).where(
            ProductVariant.product_id == variant_to_delete.product_id
        )
        variants_count = await session.scalar(count_stmt)

        if variants_count <= 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Нельзя удалить последний вариант продукта. Сначала удалите родительский продукт.",
            )
        # --------------------------------

        await session.delete(variant_to_delete)
        await session.commit()
        return ProductVariantDeleteResponse(
            success=True, message="Вариант продукта удален безвозвратно."
        )
    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Внутренняя ошибка при удалении варианта: {e}",
        )
