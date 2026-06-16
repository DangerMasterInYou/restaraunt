from sqlalchemy import select, delete as sa_delete
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status
from core.models import (
    User, Token, CartItem, CartItemModifiersAssociation, Order, OrderItem,
    Payment, OrderStatusHistory, Favorite, FavoriteGroup, FavoriteGroupItem,
    Review,
)
from auth import utils as auth_utils
from .schemas import (
    UserRoleUpdate,
    UserActiveUpdate,
    UserAdminCreate,
    UserAdminUpdate,
)


MAIN_ADMIN_EMAIL = "imoddinov@gmail.com"


def _val(x) -> str:
    return x.value if hasattr(x, "value") else str(x)


def _is_main_admin(user: User) -> bool:
    return (user.email or "").strip().lower() == MAIN_ADMIN_EMAIL


def _ensure_can_mutate(
    target: User,
    actor: User,
    *,
    new_is_active=None,
    new_role=None,
    deleting: bool = False,
) -> None:
    """Политика #2 для административных мутаций над пользователями."""
    demoting = new_role is not None and _val(new_role) != "admin"
    deactivating = new_is_active is False

    if _is_main_admin(target):
        if deleting or deactivating or demoting:
            raise HTTPException(
                status.HTTP_403_FORBIDDEN,
                "Главного администратора нельзя деактивировать, удалить или сменить роль",
            )
        return

    if _val(target.role) == "admin" and not _is_main_admin(actor):
        if deleting or deactivating or new_role is not None:
            raise HTTPException(
                status.HTTP_403_FORBIDDEN,
                "Управлять администраторами может только главный администратор",
            )


async def _revoke_user_tokens(session: AsyncSession, user_id: int) -> None:
    """Отзывает все JWT пользователя (удаляет jti) — токены перестают работать."""
    await session.execute(sa_delete(Token).where(Token.user_id == user_id))


async def get_all_users(
    session: AsyncSession, skip: int = 0, limit: int = 100
) -> list[User]:
    stmt = select(User).offset(skip).limit(limit).order_by(User.id)
    result = await session.execute(stmt)
    return result.scalars().all()


async def get_user_by_id(session: AsyncSession, user_id: int) -> User:
    user = await session.get(User, user_id)
    if not user:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Пользователь не найден")
    return user


async def create_user_admin(session: AsyncSession, data: UserAdminCreate) -> User:
    user = User(
        email=data.email,
        password=auth_utils.hash_password(data.password) if data.password else None,
        first_name=data.first_name,
        last_name=data.last_name,
        phone=data.phone,
        role=data.role,
        is_active=data.is_active,
    )
    session.add(user)
    try:
        await session.commit()
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status.HTTP_409_CONFLICT, f"Не удалось создать пользователя: {e}"
        )
    await session.refresh(user)
    return user


async def update_user_admin(
    session: AsyncSession, user_id: int, data: UserAdminUpdate, actor: User
) -> User:
    user = await get_user_by_id(session, user_id)
    fields = data.model_dump(exclude_unset=True)
    _ensure_can_mutate(
        user,
        actor,
        new_is_active=fields.get("is_active"),
        new_role=fields.get("role"),
    )
    password = fields.pop("password", None)
    if password:
        user.password = auth_utils.hash_password(password)
    for key, value in fields.items():
        setattr(user, key, value)
    if fields.get("is_active") is False:
        await _revoke_user_tokens(session, user_id)
    await session.commit()
    await session.refresh(user)
    return user


async def update_user_role(
    session: AsyncSession, user_id: int, role_data: UserRoleUpdate, actor: User
) -> User:
    user = await get_user_by_id(session, user_id)
    _ensure_can_mutate(user, actor, new_role=role_data.role)
    user.role = role_data.role
    await session.commit()
    await session.refresh(user)
    return user


async def update_user_active(
    session: AsyncSession, user_id: int, active_data: UserActiveUpdate, actor: User
) -> User:
    user = await get_user_by_id(session, user_id)
    _ensure_can_mutate(user, actor, new_is_active=active_data.is_active)
    user.is_active = active_data.is_active
    if not active_data.is_active:
        await _revoke_user_tokens(session, user_id)
    await session.commit()
    await session.refresh(user)
    return user


async def delete_user(
    session: AsyncSession, user_id: int, actor: User, *, soft: bool = True
) -> None:
    """Мягкое удаление: деактивация учётной записи; hard — безвозвратное удаление."""
    user = await get_user_by_id(session, user_id)
    _ensure_can_mutate(user, actor, deleting=True)
    await _revoke_user_tokens(session, user_id)
    if soft:
        user.is_active = False
        await session.commit()
        return
    await _hard_delete_user(session, user_id)
    await session.commit()


async def _hard_delete_user(session: AsyncSession, user_id: int) -> None:
    """Безвозвратное удаление пользователя и всех связанных данных.

    Зависимые записи удаляем явно в порядке внешних ключей (потомки раньше
    родителей). Это async-безопасно (без ленивой подгрузки коллекций во время
    flush) и не зависит от наличия ON DELETE CASCADE в БД, поэтому профиль с
    избранным и активными/архивными заказами удаляется без ошибок.
    """
    order_ids = select(Order.id).where(Order.user_id == user_id)
    cart_ids = select(CartItem.id).where(CartItem.user_id == user_id)
    group_ids = select(FavoriteGroup.id).where(FavoriteGroup.user_id == user_id)

    # заказы: позиции, оплата, история -> сами заказы
    await session.execute(
        sa_delete(OrderItem).where(OrderItem.order_id.in_(order_ids))
    )
    await session.execute(
        sa_delete(Payment).where(Payment.order_id.in_(order_ids))
    )
    await session.execute(
        sa_delete(OrderStatusHistory).where(
            OrderStatusHistory.order_id.in_(order_ids)
        )
    )
    await session.execute(sa_delete(Order).where(Order.user_id == user_id))

    # корзина: модификаторы позиций -> сами позиции
    await session.execute(
        sa_delete(CartItemModifiersAssociation).where(
            CartItemModifiersAssociation.cart_item_id.in_(cart_ids)
        )
    )
    await session.execute(sa_delete(CartItem).where(CartItem.user_id == user_id))

    # избранное: позиции групп -> группы -> одиночное избранное
    await session.execute(
        sa_delete(FavoriteGroupItem).where(
            FavoriteGroupItem.group_id.in_(group_ids)
        )
    )
    await session.execute(
        sa_delete(FavoriteGroup).where(FavoriteGroup.user_id == user_id)
    )
    await session.execute(sa_delete(Favorite).where(Favorite.user_id == user_id))

    # отзывы и сам пользователь (токены уже отозваны выше)
    await session.execute(sa_delete(Review).where(Review.user_id == user_id))
    await session.execute(sa_delete(User).where(User.id == user_id))
