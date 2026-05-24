from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from typing import Optional, List, Dict, Any

from core.models import Cart, CartFoodAssociation, Product
from api.api_v1.cart.cart_schemas import (
    CartCreate,
    CartItemOperation,
    CartSummary,
)

import logging

logger = logging.getLogger(__name__)


class CartCRUD:
    """Класс для работы с корзиной пользователя"""

    @staticmethod
    async def create_cart(
        session: AsyncSession,
        cart_data: CartCreate,
    ) -> Cart:
        """
        Создание новой корзины
        """
        # Создаем корзину
        cart = Cart(user_id=cart_data.user_id)
        session.add(cart)

        # Если есть товары, добавляем их
        if cart_data.items:
            for item in cart_data.items:
                # Получаем товар
                food = await session.get(Product, item.product_id)
                if food:
                    # Создаем связь между корзиной и товаром
                    cart_item = CartFoodAssociation(
                        count=item.quantity,
                        unit_price=food.price,
                        foods=food,
                    )
                    cart.food_details.append(cart_item)

        await session.commit()
        await session.refresh(cart)
        return cart

    @staticmethod
    async def get_cart(
        session: AsyncSession,
        user_id: int,
    ) -> Optional[Cart]:
        """
        Получение корзины пользователя
        """
        stmt = select(Cart).where(Cart.user_id == user_id)
        return await session.scalar(stmt)

    @staticmethod
    async def get_cart_with_foods(
        session: AsyncSession,
        user_id: int,
    ) -> Optional[Cart]:
        """
        Получение корзины пользователя с товарами

        Args:
            session: Асинхронная сессия БД
            user_id: ID пользователя

        Returns:
            Корзина пользователя с товарами или None, если корзина не найдена
        """
        stmt = (
            select(Cart)
            .options(
                selectinload(Cart.products_details).joinedload(
                    CartFoodAssociation.products
                ),
            )
            .where(Cart.user_id == user_id)
        )
        return await session.scalar(stmt)

    @staticmethod
    async def get_cart_with_foods_detailed(
        session: AsyncSession,
        user_id: int,
    ) -> Dict[str, Any]:
        """
        Получение детальной информации о корзине пользователя

        Args:
            session: Асинхронная сессия БД
            user_id: ID пользователя

        Returns:
            Словарь с детальной информацией о корзине
        """
        cart = await CartCRUD.get_cart_with_foods(session, user_id)

        if not cart:
            return None

        # Формируем детальную информацию
        items = []
        total = 0
        items_count = 0

        for item in cart.products_details:
            food = item.products
            item_total = item.unit_price * item.count
            total += item_total
            items_count += item.count

            items.append(
                {
                    "food_id": food.id,
                    "food_name": food.name,
                    "food_description": food.description,
                    "food_image_url": (
                        food.image_url if hasattr(food, "image_url") else None
                    ),
                    "quantity": item.count,
                    "unit_price": item.unit_price,
                    "total_price": item_total,
                }
            )

        return {
            "id": cart.id,
            "user_id": cart.user_id,
            "items": items,
            "total_amount": total,
            "items_count": items_count,
            # "created_at": cart.created_at,
            # "updated_at": cart.updated_at,
        }

    @staticmethod
    async def get_carts(
        session: AsyncSession,
        skip: int = 0,
        limit: int = 100,
    ) -> List[Cart]:
        """
        Получение списка корзин с пагинацией

        Args:
            session: Асинхронная сессия БД
            skip: Количество записей для пропуска
            limit: Максимальное количество записей для возврата

        Returns:
            Список объектов корзин
        """
        stmt = select(Cart).order_by(Cart.id).offset(skip).limit(limit)
        carts = await session.scalars(stmt)
        return list(carts)

    @staticmethod
    async def update_cart(
        session: AsyncSession,
        user_id: int,
        item: CartItemOperation,
    ) -> Optional[Cart]:
        """
        Универсальный метод для обновления корзины

        Этот метод обрабатывает все операции с товарами в корзине:
        - Добавление нового товара
        - Обновление количества существующего товара
        - Удаление товара (если quantity=0)

        Args:
            session: Асинхронная сессия БД
            user_id: ID пользователя
            item: Данные операции с товаром

        Returns:
            Обновленная корзина или None, если корзина не найдена
        """
        logger.info(
            f"Обновление корзины пользователя {user_id}, товар {item.food_id}, количество {item.quantity}"
        )

        # Получаем корзину с товарами
        stmt = (
            select(Cart)
            .options(
                selectinload(Cart.products_details).joinedload(
                    CartFoodAssociation.products
                )
            )
            .where(Cart.user_id == user_id)
        )
        cart: Optional[Cart] = await session.scalar(stmt)

        # Если корзины нет, создаем новую
        if not cart:
            if item.quantity <= 0:
                # Нет смысла создавать корзину для удаления товара
                return None

            cart = Cart(user_id=user_id)
            session.add(cart)
            await session.flush()  # Получаем ID корзины

        # Получаем товар
        food: Optional[Product] = await session.get(Product, item.food_id)
        if not food:
            logger.warning(f"Товар с ID {item.food_id} не найден")
            return None

        # Ищем товар в корзине
        existing_item = None
        for cart_item in cart.products_details:
            if cart_item.products.id == item.food_id:
                existing_item = cart_item
                break

        # Обрабатываем операцию в зависимости от количества
        if item.quantity <= 0:
            # Удаляем товар из корзины
            if existing_item:
                cart.food_details.remove(existing_item)
                await session.delete(existing_item)
        elif existing_item:
            # Обновляем количество существующего товара
            existing_item.count = item.quantity
        else:
            # Добавляем новый товар в корзину
            cart_item = CartFoodAssociation(
                count=item.quantity,
                unit_price=food.price,
                foods=food,
            )
            cart.food_details.append(cart_item)

        await session.commit()
        await session.refresh(cart)

        logger.info(f"Корзина пользователя {user_id} успешно обновлена")
        return cart

    @staticmethod
    async def remove_food_from_cart(
        session: AsyncSession,
        user_id: int,
        food_id: int,
    ) -> Optional[Cart]:
        """
        Удаление товара из корзины
        """
        return await CartCRUD.update_cart(
            session=session,
            user_id=user_id,
            item=CartItemOperation(food_id=food_id, quantity=0),
        )

    @staticmethod
    async def clear_cart(
        session: AsyncSession,
        user_id: int,
    ) -> Optional[Cart]:
        """
        Очистка корзины пользователя
        """
        cart = await CartCRUD.get_cart(session, user_id)
        if not cart:
            return None

        # Удаляем все связи с товарами
        await session.execute(
            delete(CartFoodAssociation).where(CartFoodAssociation.cart_id == cart.id)
        )

        await session.commit()
        await session.refresh(cart)
        return cart

    # @staticmethod
    # async def calculate_cart_total(
    #     session: AsyncSession,
    #     user_id: int,
    # ) -> CartSummary:
    #     """
    #     Расчет итоговой стоимости корзины
    #
    #     Args:
    #         session: Асинхронная сессия БД
    #         user_id: ID пользователя
    #
    #     Returns:
    #         Объект с информацией о стоимости корзины
    #     """
    #     cart = await CartCRUD.get_cart_with_foods(session, user_id)
    #
    #     if not cart:
    #         return CartSummary(total_amount=0, items_count=0, unique_items=0)
    #
    #     total = 0
    #     items_count = 0
    #
    #     for item in cart.food_details:
    #         total += item.unit_price * item.count
    #         items_count += item.count
    #
    #     return CartSummary(
    #         total_amount=total,
    #         items_count=items_count,
    #         unique_items=len(cart.food_details),
    #     )


# Создаем экземпляр класса для использования в приложении
cart_crud = CartCRUD()
