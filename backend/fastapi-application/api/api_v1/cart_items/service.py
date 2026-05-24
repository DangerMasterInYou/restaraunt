# cart/service.py

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
from core.models import CartItem, CartItemModifiersAssociation, ProductVariant

# --- Вспомогательная функция для сборки ответа ---


def _create_cart_response(cart_items: List[CartItem]) -> CartResponse:
    """Собирает и рассчитывает полный ответ для корзины."""
    response_items = []
    total_cart_price = 0

    for item in cart_items:
        # Рассчитываем цену для одной единицы товара с модификаторами
        base_price = item.product_variant.price
        modifiers_price = sum(
            mod.modifier.price_delta * mod.quantity for mod in item.modifier_details
        )
        price_per_one_unit = base_price + modifiers_price

        # Рассчитываемды подытог для всей строки (цена * количество)
        subtotal_price = price_per_one_unit * item.quantity
        total_cart_price += subtotal_price

        # Собираем ответ для этой строки
        response_items.append(
            CartItemResponse(
                id=item.id,
                quantity=item.quantity,
                subtotal_price=subtotal_price,
                product_variant=ProductVariantResponse.model_validate(
                    item.product_variant
                ),
                applied_modifiers=[
                    AppliedModifierResponse(
                        quantity=mod.quantity,
                        modifier=ModifierResponse.model_validate(mod.modifier),
                    )
                    for mod in item.modifier_details
                ],
            )
        )

    return CartResponse(items=response_items, total_price=total_cart_price)


# --- Основные сервисные функции ---


async def get_cart_for_user(user_id: int, session: AsyncSession) -> CartResponse:
    """Получает все товары в корзине для пользователя."""
    query = (
        select(CartItem)
        .where(CartItem.user_id == user_id)
        .options(
            # Эффективно загружаем все связанные данные, чтобы избежать N+1 запросов
            selectinload(CartItem.modifier_details).joinedload(
                CartItemModifiersAssociation.modifier
            ),
            joinedload(CartItem.product_variant).joinedload(ProductVariant.product),
        )
        .order_by(CartItem.created_at)
    )
    result = await session.execute(query)
    cart_items = result.scalars().all()

    return _create_cart_response(list(cart_items))


# Новая, улучшенная функция вместо старой 'add_item'
async def add_or_update_item(
    user_id: int, item_data: CartItemRequest, session: AsyncSession
) -> CartResponse:
    """
    Добавляет товар в корзину.
    Если товар с таким же набором модификаторов уже существует,
    увеличивает его количество. В противном случае - создает новую запись.
    Обрабатывает ошибки несуществующих ID.
    """

    # Оборачиваем ВСЮ логику изменения данных в try...except
    try:
        # --- Вся ваша предыдущая логика остается здесь ---

        # 1. Подготавливаем данные из запроса для сравнения.
        incoming_modifiers_dict = {
            mod.modifier_id: mod.quantity for mod in item_data.modifiers
        }

        # 2. Ищем потенциальных кандидатов в корзине пользователя.
        query = (
            select(CartItem)
            .where(
                CartItem.user_id == user_id,
                CartItem.product_variant_id == item_data.product_variant_id,
            )
            .options(selectinload(CartItem.modifier_details))
        )
        result = await session.execute(query)
        potential_matches = result.scalars().all()

        # 3. Перебираем кандидатов и ищем точное совпадение
        item_to_update = None
        for existing_item in potential_matches:
            existing_modifiers_dict = {
                mod.modifier_id: mod.quantity for mod in existing_item.modifier_details
            }
            if incoming_modifiers_dict == existing_modifiers_dict:
                item_to_update = existing_item
                break

        # 4. Выполняем логику "Найди или Создай"
        if item_to_update:
            item_to_update.quantity += item_data.quantity
        else:
            new_cart_item = CartItem(
                user_id=user_id,
                product_variant_id=item_data.product_variant_id,
                quantity=item_data.quantity,
            )
            session.add(new_cart_item)
            # Используем flush, чтобы ошибка внешнего ключа возникла здесь, до коммита
            await session.flush()

            for mod_data in item_data.modifiers:
                applied_mod = CartItemModifiersAssociation(
                    cart_item_id=new_cart_item.id,
                    modifier_id=mod_data.modifier_id,
                    quantity=mod_data.quantity,
                )
                session.add(applied_mod)

        # 5. Сохраняем все изменения
        await session.commit()

    # --- Вот новый блок обработки ошибок ---
    except IntegrityError as e:
        # ОБЯЗАТЕЛЬНО откатываем транзакцию, чтобы сессия осталась чистой
        await session.rollback()

        # Анализируем текст оригинальной ошибки, чтобы дать более точный ответ
        error_detail = str(e.orig)
        if "fk_cart_items_product_variant_id_product_variants" in error_detail:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Товар с ID {item_data.product_variant_id} не найден.",
            )
        if "fk_applied_modifiers_modifier_id_modifiers" in error_detail:
            # Находим ID несуществующего модификатора для более детальной ошибки
            invalid_modifier_id = -1
            for mod in item_data.modifiers:
                if str(mod.modifier_id) in error_detail:
                    invalid_modifier_id = mod.modifier_id
                    break
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Модификатор с ID {invalid_modifier_id} не найден.",
            )

        # Общая ошибка, если не удалось определить конкретную причину
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Ошибка целостности данных: {error_detail}",
        )

    # 6. Возвращаем обновленное состояние корзины в случае успеха
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

    # Находим строку в корзине
    cart_item = await session.get(CartItem, cart_item_id)

    # КРИТИЧЕСКАЯ ПРОВЕРКА БЕЗОПАСНОСТИ: убеждаемся, что пользователь меняет свою корзину
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

    # КРИТИЧЕСКАЯ ПРОВЕРКА БЕЗОПАСНОСТИ
    if not cart_item or cart_item.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Позиция в корзине не найдена.",
        )

    await session.delete(cart_item)
    await session.commit()

    return await get_cart_for_user(user_id, session)
