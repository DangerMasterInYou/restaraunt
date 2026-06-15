from typing import List, Optional
from pydantic import BaseModel, ConfigDict, field_validator


class ModifierResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    price_delta: int
    image_url: Optional[str] = None
    is_deleted: bool = False
    group_id: int

    @field_validator("price_delta", mode="before")
    @classmethod
    def coerce_price_delta(cls, v):
        if v is None:
            return 0
        return int(v)

    @field_validator("group_id", mode="before")
    @classmethod
    def coerce_group_id(cls, v):
        if v is None:
            return 0
        return int(v)


class ModifierCreate(BaseModel):
    name: str
    price_delta: int = 0
    image_url: Optional[str] = None


class ModifierUpdate(BaseModel):
    name: Optional[str] = None
    price_delta: Optional[int] = None
    image_url: Optional[str] = None


class ModifierGroupResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    is_required: bool
    is_multiselect: bool
    is_deleted: bool
    modifiers: List[ModifierResponse]


class ModifierGroupCreate(BaseModel):
    name: str
    is_required: bool = False
    is_multiselect: bool = True


class ModifierGroupUpdate(BaseModel):
    name: Optional[str] = None
    is_required: Optional[bool] = None
    is_multiselect: Optional[bool] = None


class ModifierGroupDeleteResponse(BaseModel):
    success: bool
    message: str


class AssociationResponse(BaseModel):
    success: bool
    message: str


class ModifierDeleteResponse(ModifierGroupDeleteResponse):
    pass