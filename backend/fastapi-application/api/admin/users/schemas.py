from pydantic import BaseModel, EmailStr, ConfigDict
from datetime import datetime
from core.models.user import UserRole


class UserAdminResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    email: EmailStr
    first_name: str | None
    last_name: str | None
    phone: str | None
    role: UserRole
    is_active: bool
    created_at: datetime


class UserRoleUpdate(BaseModel):
    role: UserRole


class UserActiveUpdate(BaseModel):
    is_active: bool


class UserAdminCreate(BaseModel):
    email: EmailStr
    password: str | None = None
    first_name: str | None = None
    last_name: str | None = None
    phone: str | None = None
    role: UserRole = UserRole.client
    is_active: bool = True


class UserAdminUpdate(BaseModel):
    email: EmailStr | None = None
    password: str | None = None
    first_name: str | None = None
    last_name: str | None = None
    phone: str | None = None
    role: UserRole | None = None
    is_active: bool | None = None
