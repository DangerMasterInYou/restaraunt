from datetime import datetime
from typing import List

from pydantic import BaseModel, ConfigDict


class CategoryCreate(BaseModel):
    name: str
    sort_order: int


class CategoryUpdate(BaseModel):
    name: str | None = None
    sort_order: int | None = None


class CategoryDeleteResponse(BaseModel):
    success: bool
    message: str


class CategoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    sort_order: int
    is_deleted: bool
