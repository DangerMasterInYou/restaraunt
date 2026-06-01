from fastapi import APIRouter

from core.config import settings
from .menu import router as menu_router
from .users.views import router as users_router
from .carts.views import router as carts_router

router = APIRouter(
    prefix=settings.api.v1.admin,
)

router.include_router(menu_router)
router.include_router(users_router)
router.include_router(carts_router)
