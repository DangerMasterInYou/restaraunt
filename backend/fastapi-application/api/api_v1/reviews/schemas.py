from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class ReviewCreate(BaseModel):
    order_id: int
    rating: int = Field(ge=1, le=5)
    text: Optional[str] = None


class ReviewRespond(BaseModel):
    response: str = Field(min_length=1)


class ReviewResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    order_id: int
    user_id: int
    rating: int
    text: Optional[str] = None
    response: Optional[str] = None
    responded_at: Optional[datetime] = None
    created_at: datetime
    order_number: Optional[str] = None
    customer_name: Optional[str] = None
    customer_phone: Optional[str] = None
    customer_email: Optional[str] = None
