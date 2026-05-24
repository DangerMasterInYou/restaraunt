from fastapi import APIRouter

from .category.category_views import router as category_router
from .product.views import router as product_router
from .modifier.views import router as modifier_router
from .combo.views import router as combo_router

router = APIRouter()

router.include_router(
    router=category_router,
    tags=["Admin Category"],
)

router.include_router(
    router=product_router,
    tags=["Admin Product"],
)

router.include_router(
    router=modifier_router,
    tags=["Admin Modifier"],
)

router.include_router(
    router=combo_router,
    prefix="/combo",
    tags=["Admin Combo"],
)
