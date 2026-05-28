from pydantic import (
    BaseModel,
    model_validator,
    field_validator,
    EmailStr,
    Field,
)
import re
from datetime import datetime, date

from core.models.user import UserRole


class UserSchema(BaseModel):
    email: EmailStr
    birthday: date | None = None
    first_name: str | None = None
    last_name: str | None = None
    phone: str | None = None


class UserRead(UserSchema):
    role: UserRole = UserRole.client
    is_active: bool
    created_at: datetime


class UserLoginScheme(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8)

    @field_validator("password")
    def validate_password(cls, v: str) -> str:
        if not re.search(r"\d", v):
            raise ValueError("Содержит не менее 1 цифры.")
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', v):
            raise ValueError("Содержит не менее 1 спец. символа.")
        if not re.search(r"[A-Z]", v):
            raise ValueError("Содержит не менее чем по 1 символу в верхнем регистре.")
        if not re.search(r"[a-z]", v):
            raise ValueError("Содержит не менее чем по 1 символу в нижнем регистре.")
        return v


class LoginResponseScheme(BaseModel):
    email: EmailStr
    access_token: str
    token_type: str = "bearer"


class UserRegisterScheme(UserSchema):
    password: str
    c_password: str

    # Валидация пароля
    @field_validator("password")
    def validate_password(cls, v: str) -> str:
        if len(v) < 8:  # минимум 8 символов
            raise ValueError("Пароль должен содержать не менее 8 символов.")
        if not re.search(r"\d", v):
            raise ValueError("Содержит не менее 1 цифры.")
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', v):
            raise ValueError("Содержит не менее 1 спец. символа.")
        if not re.search(r"[A-Z]", v):
            raise ValueError("Содержит не менее чем по 1 символу в верхнем регистре.")
        if not re.search(r"[a-z]", v):
            raise ValueError("Содержит не менее чем по 1 символу в нижнем регистре.")
        return v

    # Проверка совпадения паролей
    @model_validator(mode="after")
    def check_passwords_match(self):
        if self.password != self.c_password:
            raise ValueError("Пароли не совпадают!")
        return self
