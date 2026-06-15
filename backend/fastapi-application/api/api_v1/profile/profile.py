from typing import Annotated

from fastapi import Depends, HTTPException
from pydantic import BaseModel, constr
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.api_v1.auth_jwt.crud_validation import get_current_active_user_id
from core.db_helper import db_helper
from core.models import User
from fastapi import APIRouter
from datetime import datetime
from typing import Optional

router = APIRouter()


@router.get("/profile")
async def get_profile(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_active_user_id)],
):
    user: User | None = await session.scalar(select(User).where(User.id == user_id))
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user


class ProfilePatch(BaseModel):
    birthday: Optional[datetime] = None
    first_name: Optional[constr(strip_whitespace=True, min_length=1)] = None
    last_name: Optional[constr(strip_whitespace=True, min_length=1)] = None
    phone: Optional[constr(strip_whitespace=True, min_length=1)] = None


@router.patch("/profile")
async def patch_profile(
    payload: ProfilePatch,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_active_user_id)],
):
    stmt = select(User).where(User.id == user_id)
    user: User | None = await session.scalar(stmt)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    updated = False
    if payload.birthday is not None:
        user.birthday = payload.birthday
        updated = True
    if payload.first_name is not None:
        user.first_name = payload.first_name
        updated = True
    if payload.last_name is not None:
        user.last_name = payload.last_name
        updated = True
    if payload.phone is not None:
        user.phone = payload.phone
        updated = True

    if not updated:
        return user

    session.add(user)
    await session.commit()
    await session.refresh(user)
    return user


@router.delete("/profile")
async def delete_profile(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_active_user_id)],
):
    stmt = select(User).where(User.id == user_id)
    user: User | None = await session.scalar(stmt)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = False
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return {"success": True, "detail": "User deactivated"}
