from typing import Annotated, List

from fastapi import APIRouter, Depends, Path, HTTPException, status, Query, Body

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import SQLAlchemyError, IntegrityError

from core.db_helper import db_helper
from api.api_v1.cart.cart_crud import cart_crud
from api.api_v1.cart.cart_schemas import (
    CartCreate,
    CartRead,
    CartItemOperation,
)
from .cart_responses import (
    ErrorResponse,
    NotFoundResponse,
    ValidationErrorResponse,
)

router = APIRouter()


@router.post(
    "/cart-create",
    response_model=CartRead,
    status_code=status.HTTP_201_CREATED,
    responses={
        status.HTTP_201_CREATED: {"description": "Корзина успешно создана"},
        status.HTTP_400_BAD_REQUEST: {
            "model": ValidationErrorResponse,
            "description": "Ошибка валидации данных",
        },
        status.HTTP_500_INTERNAL_SERVER_ERROR: {
            "model": ErrorResponse,
            "description": "Внутренняя ошибка сервера",
        },
    },
    summary="Создать новую корзину",
    description="Создает новую корзину для пользователя с указанными товарами",
)
async def create_cart(
    cart_data: CartCreate,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """Создание новой корзины"""
    try:
        return await cart_crud.create_cart(session, cart_data)
    except IntegrityError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ошибка при создании корзины. Возможно, указаны некорректные данные.",
        )
    except SQLAlchemyError:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Ошибка при работе с базой данных",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Произошла непредвиденная ошибка: {str(e)}",
        )


@router.get(
    "/{user_id}",
    response_model=CartRead,
    responses={
        status.HTTP_200_OK: {"description": "Корзина успешно получена"},
        status.HTTP_404_NOT_FOUND: {
            "model": NotFoundResponse,
            "description": "Корзина не найдена",
        },
        status.HTTP_500_INTERNAL_SERVER_ERROR: {
            "model": ErrorResponse,
            "description": "Внутренняя ошибка сервера",
        },
    },
    summary="Получить корзину пользователя",
    description="Возвращает информацию о корзине пользователя с указанным ID",
)
async def get_cart(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: int = Path(..., description="ID пользователя"),
):
    """Получение корзины пользователя"""
    try:
        cart_data = await cart_crud.get_cart_with_foods_detailed(session, user_id)
        if not cart_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Корзина для пользователя с ID {user_id} не найдена",
            )
        return cart_data
    except HTTPException:
        raise
    except SQLAlchemyError:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Ошибка при работе с базой данных",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Произошла непредвиденная ошибка: {str(e)}",
        )


@router.get(
    "/",
    # response_model=List[CartRead],
    responses={
        status.HTTP_200_OK: {"description": "Список корзин успешно получен"},
        status.HTTP_500_INTERNAL_SERVER_ERROR: {
            "model": ErrorResponse,
            "description": "Внутренняя ошибка сервера",
        },
    },
    summary="Получить список всех корзин",
    description="Возвращает список всех корзин в системе с поддержкой пагинации",
)
async def get_carts(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    skip: int = Query(0, ge=0, description="Количество записей для пропуска"),
    limit: int = Query(
        100, ge=1, le=1000, description="Максимальное количество записей для возврата"
    ),
):
    """Получение списка всех корзин"""
    try:
        return await cart_crud.get_carts(session, skip, limit)
    except SQLAlchemyError:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Ошибка при работе с базой данных",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Произошла непредвиденная ошибка: {str(e)}",
        )


@router.patch(
    "/{user_id}/items",
    response_model=CartRead,
    responses={
        status.HTTP_200_OK: {"description": "Корзина успешно обновлена"},
        status.HTTP_404_NOT_FOUND: {
            "model": NotFoundResponse,
            "description": "Корзина или товар не найдены",
        },
        status.HTTP_400_BAD_REQUEST: {
            "model": ValidationErrorResponse,
            "description": "Ошибка валидации данных",
        },
        status.HTTP_500_INTERNAL_SERVER_ERROR: {
            "model": ErrorResponse,
            "description": "Внутренняя ошибка сервера",
        },
    },
    summary="Обновить товар в корзине",
    description="Добавляет, обновляет или удаляет товар в корзине пользователя",
)
async def update_cart_item(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    item: Annotated[CartItemOperation, Body(...)],
    user_id: int = Path(..., description="ID пользователя"),
):
    """Обновление товара в корзине"""
    try:
        result = await cart_crud.update_cart(
            session=session,
            user_id=user_id,
            item=item,
        )

        if not result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Корзина для пользователя с ID {user_id} или товар с ID {item.food_id} не найдены",
            )

        # Получаем детальную информацию о корзине для ответа
        return await cart_crud.get_cart_with_foods_detailed(session, user_id)
    except HTTPException:
        raise
    except IntegrityError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ошибка при обновлении корзины. Возможно, указаны некорректные данные.",
        )
    except SQLAlchemyError:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Ошибка при работе с базой данных",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Произошла непредвиденная ошибка: {str(e)}",
        )


@router.delete(
    "/{user_id}/items/{food_id}",
    response_model=CartRead,
    responses={
        status.HTTP_200_OK: {"description": "Товар успешно удален из корзины"},
        status.HTTP_404_NOT_FOUND: {
            "model": NotFoundResponse,
            "description": "Корзина или товар не найдены",
        },
        status.HTTP_500_INTERNAL_SERVER_ERROR: {
            "model": ErrorResponse,
            "description": "Внутренняя ошибка сервера",
        },
    },
    summary="Удалить товар из корзины",
    description="Удаляет указанный товар из корзины пользователя",
)
async def remove_item_from_cart(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: int = Path(..., description="ID пользователя"),
    food_id: int = Path(..., description="ID товара для удаления"),
):
    """Удаление товара из корзины"""
    try:
        result = await cart_crud.remove_food_from_cart(
            session=session,
            user_id=user_id,
            food_id=food_id,
        )

        if not result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Корзина для пользователя с ID {user_id} или товар с ID {food_id} не найдены",
            )

        # Получаем детальную информацию о корзине для ответа
        return await cart_crud.get_cart_with_foods_detailed(session, user_id)
    except HTTPException:
        raise
    except SQLAlchemyError:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Ошибка при работе с базой данных",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Произошла непредвиденная ошибка: {str(e)}",
        )


@router.delete(
    "/{user_id}/clear",
    response_model=CartRead,
    responses={
        status.HTTP_200_OK: {"description": "Корзина успешно очищена"},
        status.HTTP_404_NOT_FOUND: {
            "model": NotFoundResponse,
            "description": "Корзина не найдена",
        },
        status.HTTP_500_INTERNAL_SERVER_ERROR: {
            "model": ErrorResponse,
            "description": "Внутренняя ошибка сервера",
        },
    },
    summary="Очистить корзину",
    description="Удаляет все товары из корзины пользователя",
)
async def clear_cart(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: int = Path(..., description="ID пользователя"),
):
    """Очистка корзины пользователя"""
    try:
        result = await cart_crud.clear_cart(
            session=session,
            user_id=user_id,
        )

        if not result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Корзина для пользователя с ID {user_id} не найдена",
            )

        # Получаем детальную информацию о корзине для ответа
        return await cart_crud.get_cart_with_foods_detailed(session, user_id)
    except HTTPException:
        raise
    except SQLAlchemyError:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Ошибка при работе с базой данных",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Произошла непредвиденная ошибка: {str(e)}",
        )


@router.post(
    "/{user_id}/checkout",
    response_model=CartRead,
    responses={
        status.HTTP_200_OK: {"description": "Заказ успешно оформлен"},
        status.HTTP_404_NOT_FOUND: {
            "model": NotFoundResponse,
            "description": "Корзина не найдена",
        },
        status.HTTP_400_BAD_REQUEST: {
            "model": ValidationErrorResponse,
            "description": "Ошибка валидации данных или пустая корзина",
        },
        status.HTTP_500_INTERNAL_SERVER_ERROR: {
            "model": ErrorResponse,
            "description": "Внутренняя ошибка сервера",
        },
    },
    summary="Оформить заказ",
    description="Оформляет заказ на основе содержимого корзины пользователя",
)
async def checkout_cart(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: int = Path(..., description="ID пользователя"),
):
    """Оформление заказа на основе корзины"""
    try:
        # Получаем корзину пользователя
        cart_data = await cart_crud.get_cart_with_foods_detailed(session, user_id)
        if not cart_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Корзина для пользователя с ID {user_id} не найдена",
            )

        # Проверяем, что корзина не пуста
        if not cart_data["items"] or len(cart_data["items"]) == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Невозможно оформить заказ: корзина пуста",
            )

        # Здесь можно добавить логику создания заказа на основе корзины
        # Например, создание записи в таблице Orders
        # и связывание её с товарами из корзины

        # После создания заказа можно очистить корзину
        await cart_crud.clear_cart(session, user_id)

        # Возвращаем информацию о корзине (теперь пустой)
        return await cart_crud.get_cart_with_foods_detailed(session, user_id)
    except HTTPException:
        raise
    except SQLAlchemyError:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Ошибка при работе с базой данных",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Произошла непредвиденная ошибка: {str(e)}",
        )
