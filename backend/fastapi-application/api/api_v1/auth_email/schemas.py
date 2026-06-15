import re

from pydantic import BaseModel, EmailStr, field_validator

from core.models.user import UserRole


_EMAIL_RE = re.compile(r"^[A-Za-z0-9._%+\-]+@[a-z]+\.[a-z]+$")


def _validate_email(value: str) -> str:
    if not _EMAIL_RE.match(str(value)):
        raise ValueError(
            "Некорректный email: после @ допустимы только строчные "
            "латинские буквы и одна точка домена (например name@mail.ru)"
        )
    return value


class EmailRequestScheme(BaseModel):
    email: EmailStr

    @field_validator("email")
    @classmethod
    def _check_email(cls, v: str) -> str:
        return _validate_email(v)


class EmailResponseScheme(BaseModel):
    success: bool
    message: str


class LoginSchema(BaseModel):
    email: EmailStr
    code: str

    @field_validator("email")
    @classmethod
    def _check_email(cls, v: str) -> str:
        return _validate_email(v)


class ResponseUserDataScheme(BaseModel):
    id: int
    email: EmailStr
    role: UserRole


class ResponseLoginSchema(BaseModel):
    success: bool
    token: str
    user: ResponseUserDataScheme
