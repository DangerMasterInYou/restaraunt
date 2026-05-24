from typing import List

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload, selectinload

from .schemas import (
    ProductScheme,
    FlatProductSchema,
    ModifierGroupSchema,
    ModifierSchema,
)
from core.models import Product, ProductVariant, ModifierGroup, Category


async def get_products(session: AsyncSession) -> List[FlatProductSchema]:
    results = await session.scalars(
        select(Category)
        .options(
            selectinload(Category.products)
            .selectinload(Product.variants)
            .selectinload(ProductVariant.modifier_groups)
            .selectinload(ModifierGroup.modifiers),
        )
        .order_by(Category.sort_order)
    )
    nested_categories: list[Category] = list(results.all())
    if not nested_categories:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Menu is empty"
        )
    flat_menu_items: list[FlatProductSchema] = []

    for category in nested_categories:
        for product in category.products:
            # ---> НАЧАЛО БЛОКА ДЛЯ ОДНОГО ВАРИАНТА <---
            for variant in product.variants:

                # --- Подготовка полей ---
                full_name = product.name
                if variant.name:
                    full_name += f" {variant.name}"
                full_description = product.description
                if variant.description:
                    full_description = f"{full_description}\n{variant.description}"
                image_url = variant.image_url or product.image_url

                flat_item = FlatProductSchema(
                    id=variant.id,
                    name=full_name,
                    description=full_description,
                    image_url=image_url,
                    category=category.name,
                    price=variant.price,
                    value=variant.value,
                    unit=variant.unit,
                    sku=variant.sku,
                    is_available=variant.is_available,
                    modifier_groups=variant.modifier_groups,
                )
                flat_menu_items.append(flat_item)

    return flat_menu_items


async def get_product_by_id(
    session: AsyncSession, product_id: int
) -> FlatProductSchema:
    product_variant: ProductVariant | None = await session.scalar(
        select(ProductVariant)
        .options(
            joinedload(ProductVariant.product).joinedload(Product.category),
            selectinload(ProductVariant.modifier_groups).selectinload(
                ModifierGroup.modifiers
            ),
        )
        .where(ProductVariant.id == product_id)
    )
    if product_variant is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Product not found"
        )
    product = product_variant.product
    # --- Подготовка полей ---
    full_name = product.name
    if product_variant.name:
        full_name += f" {product_variant.name}"
    full_description = product.description
    if product_variant.description:
        full_description = f"{full_description}\n{product_variant.description}"
    image_url = product_variant.image_url or product.image_url

    return FlatProductSchema(
        id=product_variant.id,
        name=full_name,
        description=full_description,
        image_url=image_url,
        category=product.category.name,
        price=product_variant.price,
        value=product_variant.value,
        unit=product_variant.unit,
        sku=product_variant.sku,
        is_available=product_variant.is_available,
        modifier_groups=product_variant.modifier_groups,
    )
