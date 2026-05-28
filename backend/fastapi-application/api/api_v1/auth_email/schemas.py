from pydantic import BaseModel, EmailStr

from core.models.user import UserRole


class EmailRequestScheme(BaseModel):
    email: EmailStr


class EmailResponseScheme(BaseModel):
    success: bool
    message: str


class LoginSchema(BaseModel):
    email: EmailStr
    code: str


class ResponseUserDataScheme(BaseModel):
    id: int
    email: EmailStr
    role: UserRole


class ResponseLoginSchema(BaseModel):
    success: bool
    token: str
    user: ResponseUserDataScheme
