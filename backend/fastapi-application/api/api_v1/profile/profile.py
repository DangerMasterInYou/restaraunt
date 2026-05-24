from typing import Annotated

from fastapi import Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.api_v1.auth_jwt.crud_validation import get_current_user_id
from core.db_helper import db_helper
from core.models import User
from fastapi import APIRouter

router = APIRouter()


@router.get("/profile")
async def get_profile(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    user_id: Annotated[int, Depends(get_current_user_id)],
):
    user: User | None = await session.scalar(select(User).where(User.id == user_id))
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user
