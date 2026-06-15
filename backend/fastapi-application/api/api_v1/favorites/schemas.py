from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field


class FavoriteGroupCreate(BaseModel):
    name: str = Field(min_length=1, max_length=100)


class FavoriteGroupRename(BaseModel):
    name: str = Field(min_length=1, max_length=100)


class FavoriteItemCreate(BaseModel):
    product_variant_id: int
    quantity: int = Field(default=1, ge=1)
    modifier_ids: List[int] = Field(default_factory=list)


class FavoriteItemResponse(BaseModel):
    id: int
    product_variant_id: int
    quantity: int
    modifier_ids: List[int]
    product_name: Optional[str] = None
    variant_name: Optional[str] = None
    image_url: Optional[str] = None
    modifier_names: List[str] = Field(default_factory=list)
    price: int = 0


class FavoriteGroupResponse(BaseModel):
    id: int
    name: str
    created_at: datetime
    items: List[FavoriteItemResponse] = Field(default_factory=list)
