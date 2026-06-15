from fastapi import APIRouter

from core.config import settings

from .auth_jwt.views import router as auth_jwt_router

from .menu.views import router as menu_router

from .cart_items.views import router as cart_router

from .auth_email.views import router as auth_email_router
from .menu.load_images import router as load_images_router


from .profile.profile import router as profiles_router
from .orders import views as orders_views
from .promotions import views as promotions_views
from .payments import views as payments_views
from .reviews import views as reviews_views
from .favorites import views as favorites_views


router = APIRouter(
)

router.include_router(orders_views.router)
router.include_router(orders_views.operator_router)
router.include_router(orders_views.admin_router)

router.include_router(promotions_views.public_router)
router.include_router(promotions_views.admin_router)

router.include_router(payments_views.router)

router.include_router(reviews_views.router)
router.include_router(reviews_views.staff_router)
router.include_router(reviews_views.admin_router)

router.include_router(favorites_views.router)


router.include_router(
    router=auth_email_router,
    prefix=settings.api.v1.auth,
    tags=["Auth Email"],
)

router.include_router(
    router=load_images_router,
    tags=["Images"],
)


router.include_router(
    router=profiles_router,
    tags=["Profile"],
)


router.include_router(
    router=menu_router,
    prefix=settings.api.v1.menu,
    tags=["Menu"],
)


router.include_router(
    router=cart_router,
    prefix=settings.api.v1.cart,
    tags=["Shopping Cart"],
)





