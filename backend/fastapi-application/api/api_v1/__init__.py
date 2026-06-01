from fastapi import APIRouter

from core.config import settings

from .auth_jwt.views import router as auth_jwt_router

# from .menu.menu_views import router as menu_router
from .menu.views import router as menu_router

# from .cart.cart_views import router as cart_router
from .cart_items.views import router as cart_router

from .auth_email.views import router as auth_email_router
from .menu.load_images import router as load_images_router

# from .orders.cart import router as orders_cart_router
# from .new_orders.views import router as new_orders_router

from .profile.profile import router as profiles_router
from .orders import views as orders_views

# from .new_orders.operator import router as new_orders_operator_router

router = APIRouter(
    # prefix=settings.api.v1.prefix,
    # tags=["api V1"],
)
# router.include_router(
#     router=auth_jwt_router,
#     # prefix=settings.api.v1.auth,
#     tags=["User Auth"],
# )

# Подключаем клиентские эндпоинты заказов
router.include_router(orders_views.router)
# Подключаем операторские эндпоинты заказов
router.include_router(orders_views.operator_router)
# Подключаем админские эндпоинты заказов
router.include_router(orders_views.admin_router)


router.include_router(
    router=auth_email_router,
    prefix=settings.api.v1.auth,
    tags=["Auth Email"],
)

router.include_router(
    router=load_images_router,
    # prefix=settings.api.v1.menu,
    tags=["Images"],
)


router.include_router(
    router=profiles_router,
    # prefix=settings.api.v1.menu,
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


# router.include_router(
#     router=new_orders_router,
#     # prefix=settings.api.v1.,
#     tags=["Orders"],
# )


# router.include_router(
#     router=new_orders_operator_router,
#     # prefix=settings.api.v1.,
#     tags=["Operator"],
# )

# router.include_router(
#     router=orders_cart_router,
#     # prefix=settings.api.v1.auth,
#     tags=["Shopping Cart"],
# )
