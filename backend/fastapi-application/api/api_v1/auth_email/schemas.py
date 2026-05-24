from pydantic import BaseModel, EmailStr


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


class ResponseLoginSchema(BaseModel):
    success: bool
    token: str
    user: ResponseUserDataScheme
