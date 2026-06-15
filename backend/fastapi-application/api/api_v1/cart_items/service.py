
from typing import List
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload, joinedload

from .schemas import (
    CartResponse,
    CartItemRequest,
    CartItemResponse,
    AppliedModifierResponse,
    ModifierResponse,
    ProductVariantResponse,
)
from core.models import CartItem, CartItemModifiersAssociation, Modifier, ProductVariant
from api.api_v1.promotions.discounts import compute_cart_discount



async def _create_cart_response(
    cart_items: List[CartItem],
    session: AsyncSession,
    user_birthday=None,
) -> CartResponse:
    """Собирает и рассчитывает полный ответ для корзины (со скидками по акциям)."""
    response_items = []
    total_cart_price = 0
    line_items = []

    for item in cart_items:
        base_price = item.product_variant.price
        modifiers_price = sum(
            mod.modifier.price_delta * mod.quantity for mod in item.modifier_details
        )
        price_per_one_unit = base_price + modifiers_price

        subtotal_price = price_per_one_unit * item.quantity
        total_cart_price += subtotal_price

        product = item.product_variant.product
        line_items.append(
            {
                "category_id": product.category_id if product else None,
                "product_id": item.product_variant.product_id,
                "subtotal": subtotal_price,
            }
        )

        pv = ProductVariantResponse.model_validate(item.product_variant)
        pv.image_url = item.product_variant.image_url or (
            product.image_url if product else None
        )

        response_items.append(
            CartItemResponse(
                id=item.id,
                quantity=item.quantity,
                subtotal_price=subtotal_price,
                product_name=item.product_variant.product.name
                if item.product_variant.product
                else None,
                product_variant=pv,
                applied_modifiers=[
                    AppliedModifierResponse(
                        quantity=mod.quantity,
                        modifier=ModifierResponse.model_validate(mod.modifier),
                    )
                    for mod in item.modifier_details
                ],
            )
        )

    discount, applied = await compute_cart_discount(
        session, line_items, user_birthday=user_birthday
    )
    return CartResponse(
        items=response_items,
        total_price=total_cart_price - discount,
        subtotal_price=total_cart_price,
        discount=discount,
        applied_promotions=applied,
    )




async def get_cart_for_user(user_id: int, session: AsyncSession) -> CartResponse:
    """Получает все товары в корзине для пользователя."""
    query = (
        select(CartItem)
        .where(CartItem.user_id == user_id)
        .options(
            selectinload(CartItem.modifier_details).joinedload(
                CartItemModifiersAssociation.modifier
            ),
            joinedload(CartItem.product_variant).joinedload(ProductVariant.product),
            joinedload(CartItem.product_variant).selectinload(
                ProductVariant.modifier_groups
            ),
        )
        .order_by(CartItem.created_at)
    )
    result = await session.execute(query)
    cart_items = result.scalars().all()

    from core.models import User

    user = await session.get(User, user_id)
    user_birthday = user.birthday if user else None

    return await _create_cart_response(
        list(cart_items), session, user_birthday=user_birthday
    )


async def add_or_update_item(
    user_id: int, item_data: CartItemRequest, session: AsyncSession
) -> CartResponse:
    """
    Добавляет товар в корзину.
    Если товар с таким же набором модификаторов уже существует,
    увеличивает его количество. В противном случае - создает новую запись.
    Обрабатывает ошибки несуществующих ID.
    """

    try:
        variant = await session.get(ProductVariant, item_data.product_variant_id)
        if not variant or variant.is_deleted or not variant.is_available:
            default_variant = (
                await session.execute(
                    select(ProductVariant)
                    .where(
                        ProductVariant.product_id == item_data.product_variant_id,
                        ProductVariant.is_deleted == False,
                        ProductVariant.is_available == True,
                    )
                    .limit(1)
                )
            ).scalars().first()

            if not default_variant:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Вариант товара ID {item_data.product_variant_id} не найден.",
                )
            variant = default_variant

        final_product_variant_id = variant.id

        modifier_ids = [m.modifier_id for m in item_data.modifiers]
        if modifier_ids:
            unique_ids = set(modifier_ids)
            modifiers = (
                await session.execute(
                    select(Modifier)
                    .where(Modifier.id.in_(list(unique_ids)))
                    .where(Modifier.is_deleted == False)
                )
            ).scalars().all()
            if len(modifiers) != len(unique_ids):
                missing_ids = unique_ids - {m.id for m in modifiers}
                missing_id = next(iter(missing_ids))
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Модификатор ID {missing_id} не найден.",
                )


        incoming_modifiers_dict = {
            mod.modifier_id: mod.quantity for mod in item_data.modifiers
        }

        query = (
            select(CartItem)
            .where(
                CartItem.user_id == user_id,
                CartItem.product_variant_id == final_product_variant_id,
            )
            .options(selectinload(CartItem.modifier_details))
        )
        result = await session.execute(query)
        potential_matches = result.scalars().all()

        item_to_update = None
        for existing_item in potential_matches:
            existing_modifiers_dict = {
                mod.modifier_id: mod.quantity for mod in existing_item.modifier_details
            }
            if incoming_modifiers_dict == existing_modifiers_dict:
                item_to_update = existing_item
                break

        if item_to_update:
            item_to_update.quantity += item_data.quantity
        else:
            new_cart_item = CartItem(
                user_id=user_id,
                product_variant_id=final_product_variant_id,
                quantity=item_data.quantity,
            )
            session.add(new_cart_item)
            await session.flush()

            for mod_data in item_data.modifiers:
                applied_mod = CartItemModifiersAssociation(
                    cart_item_id=new_cart_item.id,
                    modifier_id=mod_data.modifier_id,
                    quantity=mod_data.quantity,
                )
                session.add(applied_mod)

        await session.commit()

    except IntegrityError as e:
        await session.rollback()

        error_detail = str(e.orig)
        if "fk_cart_items_product_variant_id_product_variants" in error_detail:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Товар с ID {item_data.product_variant_id} не найден.",
            )
        if "fk_applied_modifiers_modifier_id_modifiers" in error_detail:
            invalid_modifier_id = -1
            for mod in item_data.modifiers:
                if str(mod.modifier_id) in error_detail:
                    invalid_modifier_id = mod.modifier_id
                    break
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Модификатор с ID {invalid_modifier_id} не найден.",
            )

        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Ошибка целостности данных: {error_detail}",
        )

    return await get_cart_for_user(user_id, session)


async def update_item_quantity(
    user_id: int, cart_item_id: int, quantity: int, session: AsyncSession
) -> CartResponse:
    """Обновляет количество товара в строке корзины."""
    if quantity <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Количество должно быть положительным числом. Для удаления используйте DELETE.",
        )

    cart_item = await session.get(CartItem, cart_item_id)

    if not cart_item or cart_item.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Позиция в корзине не найдена.",
        )

    cart_item.quantity = quantity
    await session.commit()

    return await get_cart_for_user(user_id, session)


async def remove_item(
    user_id: int, cart_item_id: int, session: AsyncSession
) -> CartResponse:
    """Удаляет строку из корзины."""
    cart_item = await session.get(CartItem, cart_item_id)

    if not cart_item or cart_item.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Позиция в корзине не найдена.",
        )

    await session.delete(cart_item)
    await session.commit()

    return await get_cart_for_user(user_id, session)
