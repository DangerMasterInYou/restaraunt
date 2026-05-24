from pydantic import BaseModel
from typing import Any, Dict, List, Optional, Union


class ErrorResponse(BaseModel):
    detail: str


class ValidationErrorResponse(BaseModel):
    detail: List[Dict[str, Any]]


class NotFoundResponse(BaseModel):
    detail: str


class SuccessResponse(BaseModel):
    detail: str
