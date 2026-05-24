# from typing import Annotated
#
# from fastapi import APIRouter, Depends, Path, HTTPException, status
# from sqlalchemy import select
# from sqlalchemy.ext.asyncio import AsyncSession
# from sqlalchemy.orm import joinedload, selectinload
#
# from core.db_helper import db_helper
# from core.models import Product, Category
# from .menu_schemas import (
#     FoodReadSchema,
#     FoodCreateSchema,
#     FoodUpdateSchema,
#     FoodUpdatePartialSchema,
# )
#
# router = APIRouter()
#
#
# @router.get(
#     "/{product_category}/{product_name}",
#     response_model=FoodReadSchema,
# )
# async def get_product_by_category_and_name(
#     product_category: Annotated[str, Path],
#     product_name: Annotated[str, Path],
#     session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
# ):
#
#     stmt = (
#         select(Product)
#         .options(joinedload(Product.category))
#         .where(
#             Product.name == product_name,
#             Product.category.has(Category.name == product_category),
#         )
#     )
#     product = await session.scalar(stmt)
#
#     if product:
#         return product
#     else:
#         raise HTTPException(
#             status_code=status.HTTP_404_NOT_FOUND,
#             detail=f"Dishes {product_name} with category {product_category} not found",
#         )
#
#
# @router.get(
#     "/{product_category}",
#     response_model=list[FoodReadSchema],
#     status_code=status.HTTP_200_OK,
# )
# async def get_products_by_category(
#     product_category: Annotated[str, Path],
#     session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
# ):
#
#     stmt = (
#         select(Product)
#         .join(Product.category)
#         .options(joinedload(Product.category))
#         .where(Category.name == product_category)
#         .order_by(Product.id)
#     )
#
#     products = await session.scalars(stmt)
#     products_list = products.all()
#     if products_list:
#         return products_list
#     else:
#         raise HTTPException(
#             status_code=status.HTTP_404_NOT_FOUND,
#             detail=f"Category {product_category} not found",
#         )
#
#
# # @router.post(
# #     "/",
# #     response_model=FoodReadSchema,
# #     status_code=status.HTTP_201_CREATED,
# # )
# # async def create_food(
# #     food_data: FoodCreateSchema,
# #     session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
# # ):
# #     # нужно получить категории и проверить есть категория с введенным id
# #     food = Food(**food_data.model_dump())
# #     session.add(food)
# #     await session.commit()
# #     return food
# #
# #
# # @router.patch("/", response_model=FoodReadSchema)
# # async def update_food(
# #     food_in: FoodUpdatePartialSchema,
# #     food: Annotated[Food, Depends(get_food_by_id)],
# #     session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
# # ):
# #     return await crud.foods.update_food(
# #         session=session,
# #         food=food,
# #         food_update=food_in,
# #         partial=True,
# #     )
# #
# #
# # @router.put("/", response_model=FoodReadSchema)
# # async def update_partial_food(
# #     food_in: FoodUpdateSchema,
# #     food: Annotated[Food, Depends(get_food_by_id)],
# #     session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
# # ):
# #     return await crud.foods.update_food(
# #         session=session,
# #         food=food,
# #         food_update=food_in,
# #         partial=False,
# #     )
# #
# #
# # @router.delete("/", status_code=status.HTTP_204_NO_CONTENT)
# # async def delete_food(
# #     food: Annotated[Food, Depends(get_food_by_id)],
# #     session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
# # ):
# #     await crud.foods.delete_food(session, food)
