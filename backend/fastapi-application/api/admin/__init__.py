from fastapi import APIRouter, Depends

from core.config import settings
from api.api_v1.orders.views import require_admin
from .menu import router as menu_router
from .users.views import router as users_router
from .carts.views import router as carts_router

router = APIRouter(
    prefix=settings.api.v1.admin,
    dependencies=[Depends(require_admin)],
)

router.include_router(menu_router)
router.include_router(users_router)
router.include_router(carts_router)
