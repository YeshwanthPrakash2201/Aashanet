from pydantic import BaseModel


class UserCreate(BaseModel):
    username: str
    password: str
    role: str
    full_name: str


class UserResponse(BaseModel):
    id: str
    username: str
    role: str
    full_name: str
    is_active: bool

class LoginRequest(BaseModel):
    username: str
    password: str


class LoginResponse(BaseModel):
    message: str
    access_token: str
    token_type: str
    username: str
    role: str
    full_name: str