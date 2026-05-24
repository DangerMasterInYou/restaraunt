from fastapi import APIRouter

from core.config import settings
from .menu import router as menu_router


router = APIRouter(
    prefix=settings.api.v1.admin,
)

router.include_router(
    router=menu_router,
    # tags=["Admin menu"],
)
