# from pydantic import BaseModel, ConfigDict
#
#
# class FoodBaseSchema(BaseModel):
#     name: str
#     description: str | None = None
#     price: int
#     image_url: str | None = None
#     weight_g: int | None = None
#     volume_ml: int | None = None
#     stock: int
#     is_available: bool
#     # created_at: str
#     # updated_at: str
#     category_id: int
#
#
# class FoodReadSchema(FoodBaseSchema):
#     model_config = ConfigDict(from_attributes=True)
#     id: int
#
#
# class FoodCreateSchema(FoodBaseSchema):
#     pass
#
#
# class FoodUpdateSchema(FoodCreateSchema):
#     pass
#
#
# class FoodUpdatePartialSchema(FoodCreateSchema):
#     name: str | None = None
#     description: str | None = None
#     price: int | None = None
#     image_url: str | None = None
#     weight_g: int | None = None
#     volume_ml: int | None = None
#     stock: int | None = None
#     is_available: bool | None = None
#     category_id: int | None = None
#
#
# class FoodDeleteSchema(FoodCreateSchema):
#     pass
