"""Auth request and response models. docs/API_CONTRACT.md §2.

OWNER: Shreekumar.
"""

from __future__ import annotations

import uuid

from pydantic import BaseModel, EmailStr, Field

from app.contracts.enums import Role


class OtpRequestIn(BaseModel):
    phone: str = Field(min_length=8, max_length=20, examples=["+919876543210"])


class OtpRequestOut(BaseModel):
    request_id: uuid.UUID
    expires_in: int = Field(description="Seconds until the code stops working")


class OtpVerifyIn(BaseModel):
    request_id: uuid.UUID
    otp: str = Field(min_length=4, max_length=10)


class LoginIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=256)


class DemoLoginIn(BaseModel):
    demo_code: str = Field(default="SIH2026", description="Demo authentication code")


class UserOut(BaseModel):
    id: uuid.UUID
    role: Role
    name: str
    phone: str | None = None
    email: str | None = None


class TokenOut(BaseModel):
    """docs/API_CONTRACT.md §2 — the shape both verify and login return."""

    access_token: str
    refresh_token: str
    user: UserOut
