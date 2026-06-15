from datetime import date
from typing import Optional

from pydantic import BaseModel, ConfigDict

from core.models import PromotionType, PromotionTargetType


class PromotionBase(BaseModel):
    title: str
    description: Optional[str] = None
    discount_label: Optional[str] = None
    promo_type: PromotionType = PromotionType.percent
    discount_value: Optional[int] = None
    min_order_amount: Optional[int] = None
    target_type: PromotionTargetType = PromotionTargetType.all
    target_id: Optional[int] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    days_of_week: Optional[str] = None
    is_active: bool = True
    is_birthday: bool = False


class PromotionCreate(PromotionBase):
    pass


class PromotionUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    discount_label: Optional[str] = None
    promo_type: Optional[PromotionType] = None
    discount_value: Optional[int] = None
    min_order_amount: Optional[int] = None
    target_type: Optional[PromotionTargetType] = None
    target_id: Optional[int] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    days_of_week: Optional[str] = None
    is_active: Optional[bool] = None
    is_birthday: Optional[bool] = None


class PromotionResponse(PromotionBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class PromotionDeleteResponse(BaseModel):
    success: bool
    message: str
