from fastapi import APIRouter

from core.config import settings
from .api_v1 import router as api_v1_router
from .admin import router as admin_router

router = APIRouter()
router.include_router(api_v1_router)
router.include_router(admin_router)
