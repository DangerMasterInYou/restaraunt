from typing import List
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload, selectinload, with_loader_criteria
from .schemas import FlatProductSchema
from core.models import Product, ProductVariant, ModifierGroup, Category, Modifier

async def get_products(session: AsyncSession) -> List[FlatProductSchema]:
    results = await session.scalars(
        select(Category)
        .where(Category.is_deleted == False)
        .options(
            selectinload(Category.products)
            .selectinload(Product.variants)
            .selectinload(ProductVariant.modifier_groups)
            .selectinload(ModifierGroup.modifiers),

            with_loader_criteria(Product, Product.is_deleted == False),
            with_loader_criteria(ProductVariant, (ProductVariant.is_deleted == False) & (ProductVariant.is_available == True)),
            with_loader_criteria(ModifierGroup, ModifierGroup.is_deleted == False),
            with_loader_criteria(Modifier, Modifier.is_deleted == False)
        )
        .order_by(Category.sort_order)
    )
    nested_categories: list[Category] = list(results.all())
    if not nested_categories:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Menu is empty")

    flat_menu_items: list[FlatProductSchema] = []
    for category in nested_categories:
        for product in sorted(
            category.products, key=lambda p: (p.sort_order, p.id)
        ):
            for variant in product.variants:
                full_name = product.name
                if variant.name:
                    full_name += f" {variant.name}"

                full_description = product.description
                if variant.description:
                    full_description = f"{full_description}\n{variant.description}"

                image_url = variant.image_url or product.image_url

                flat_item = FlatProductSchema(
                    id=variant.id,
                    product_id=product.id,
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
        session: AsyncSession,
        product_id: int,
        *,
        catalog_only: bool = True,
) -> FlatProductSchema:
    """catalog_only=True — только для витрины (активные позиции). False — исторический срез заказа."""
    stmt = (
        select(ProductVariant)
        .options(
            joinedload(ProductVariant.product).joinedload(Product.category),
            selectinload(ProductVariant.modifier_groups).selectinload(ModifierGroup.modifiers),
        )
        .where(ProductVariant.id == product_id)
    )
    if catalog_only:
        stmt = stmt.where(
            ProductVariant.is_deleted == False,
            ProductVariant.is_available == True,
            )

    product_variant: ProductVariant | None = await session.scalar(stmt)
    if product_variant is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    if catalog_only:
        product = product_variant.product
        if product.is_deleted or product.category.is_deleted:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
        product_variant.modifier_groups = [
            g
            for g in product_variant.modifier_groups
            if not g.is_deleted
        ]
        for group in product_variant.modifier_groups:
            group.modifiers = [m for m in group.modifiers if not m.is_deleted]

    product = product_variant.product
    full_name = product.name
    if product_variant.name:
        full_name += f" {product_variant.name}"

    full_description = product.description
    if product_variant.description:
        if full_description:
            full_description = f"{full_description}\n{product_variant.description}"
        else:
            full_description = product_variant.description

    image_url = product_variant.image_url or product.image_url

    return FlatProductSchema(
        id=product_variant.id,
        product_id=product.id,
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