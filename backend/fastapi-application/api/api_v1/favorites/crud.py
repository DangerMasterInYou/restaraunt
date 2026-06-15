from typing import Dict, List

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload, joinedload

from core.models import (
    FavoriteGroup,
    FavoriteGroupItem,
    Modifier,
    ProductVariant,
)
from .schemas import (
    FavoriteGroupCreate,
    FavoriteGroupResponse,
    FavoriteItemCreate,
    FavoriteItemResponse,
)


async def _get_owned_group(
    user_id: int, group_id: int, session: AsyncSession
) -> FavoriteGroup:
    group = await session.scalar(
        select(FavoriteGroup)
        .where(FavoriteGroup.id == group_id, FavoriteGroup.user_id == user_id)
        .options(
            selectinload(FavoriteGroup.items)
            .joinedload(FavoriteGroupItem.product_variant)
            .joinedload(ProductVariant.product)
        )
    )
    if group is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Группа не найдена"
        )
    return group


async def _modifier_name_map(
    item_lists, session: AsyncSession
) -> Dict[int, Modifier]:
    """Один запрос на все модификаторы всех переданных позиций (без N+1)."""
    ids = {
        mid
        for items in item_lists
        for item in items
        for mid in (item.modifier_ids or [])
    }
    if not ids:
        return {}
    rows = await session.scalars(select(Modifier).where(Modifier.id.in_(ids)))
    return {m.id: m for m in rows}


def _serialize_item(
    item: FavoriteGroupItem, mods: Dict[int, Modifier]
) -> FavoriteItemResponse:
    pv = item.product_variant
    product = pv.product if pv else None
    mod_ids = item.modifier_ids or []
    chosen = [mods[mid] for mid in mod_ids if mid in mods]
    base = pv.price if pv else 0
    price = base + sum(m.price_delta for m in chosen)
    image_url = None
    if pv:
        image_url = pv.image_url or (product.image_url if product else None)
    return FavoriteItemResponse(
        id=item.id,
        product_variant_id=item.product_variant_id,
        quantity=item.quantity,
        modifier_ids=mod_ids,
        product_name=product.name if product else None,
        variant_name=pv.name if pv else None,
        image_url=image_url,
        modifier_names=[m.name for m in chosen],
        price=price,
    )


def _serialize_group(
    group: FavoriteGroup, mods: Dict[int, Modifier]
) -> FavoriteGroupResponse:
    return FavoriteGroupResponse(
        id=group.id,
        name=group.name,
        created_at=group.created_at,
        items=[_serialize_item(it, mods) for it in group.items],
    )


async def list_groups(
    user_id: int, session: AsyncSession
) -> List[FavoriteGroupResponse]:
    groups = (
        await session.scalars(
            select(FavoriteGroup)
            .where(FavoriteGroup.user_id == user_id)
            .options(
                selectinload(FavoriteGroup.items)
                .joinedload(FavoriteGroupItem.product_variant)
                .joinedload(ProductVariant.product)
            )
            .order_by(FavoriteGroup.created_at.desc())
        )
    ).unique().all()
    mods = await _modifier_name_map([g.items for g in groups], session)
    return [_serialize_group(g, mods) for g in groups]


async def create_group(
    user_id: int, data: FavoriteGroupCreate, session: AsyncSession
) -> FavoriteGroupResponse:
    group = FavoriteGroup(user_id=user_id, name=data.name.strip())
    session.add(group)
    await session.commit()
    await session.refresh(group, attribute_names=["items"])
    return _serialize_group(group, {})


async def rename_group(
    user_id: int, group_id: int, name: str, session: AsyncSession
) -> FavoriteGroupResponse:
    group = await _get_owned_group(user_id, group_id, session)
    group.name = name.strip()
    await session.commit()
    mods = await _modifier_name_map([group.items], session)
    return _serialize_group(group, mods)


async def delete_group(
    user_id: int, group_id: int, session: AsyncSession
) -> None:
    group = await _get_owned_group(user_id, group_id, session)
    await session.delete(group)
    await session.commit()


async def add_item(
    user_id: int,
    group_id: int,
    data: FavoriteItemCreate,
    session: AsyncSession,
) -> FavoriteGroupResponse:
    group = await _get_owned_group(user_id, group_id, session)
    variant = await session.get(ProductVariant, data.product_variant_id)
    if variant is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Вариант продукта не найден",
        )
    item = FavoriteGroupItem(
        group_id=group.id,
        product_variant_id=data.product_variant_id,
        quantity=data.quantity,
        modifier_ids=list(dict.fromkeys(data.modifier_ids)),
    )
    session.add(item)
    await session.commit()
    refreshed = await _get_owned_group(user_id, group_id, session)
    mods = await _modifier_name_map([refreshed.items], session)
    return _serialize_group(refreshed, mods)


async def add_group_to_cart(
    user_id: int, group_id: int, session: AsyncSession
) -> int:
    """#5: одним нажатием продублировать всё содержимое группы в корзину.

    Переиспользуем сервис корзины (дедуп по составу, валидация, модификаторы).
    Недоступные/удалённые позиции пропускаем, чтобы одна устаревшая позиция не
    рушила всю операцию. Возвращает число успешно добавленных позиций.
    """
    from api.api_v1.cart_items.service import add_or_update_item
    from api.api_v1.cart_items.schemas import (
        CartItemRequest,
        AppliedModifierCreate,
    )

    group = await _get_owned_group(user_id, group_id, session)
    added = 0
    for item in group.items:
        req = CartItemRequest(
            product_variant_id=item.product_variant_id,
            quantity=item.quantity,
            modifiers=[
                AppliedModifierCreate(modifier_id=mid, quantity=1)
                for mid in (item.modifier_ids or [])
            ],
        )
        try:
            await add_or_update_item(user_id, req, session)
            added += 1
        except HTTPException:
            continue
    return added


async def remove_item(
    user_id: int, item_id: int, session: AsyncSession
) -> None:
    item = await session.scalar(
        select(FavoriteGroupItem)
        .join(FavoriteGroup, FavoriteGroup.id == FavoriteGroupItem.group_id)
        .where(
            FavoriteGroupItem.id == item_id,
            FavoriteGroup.user_id == user_id,
        )
    )
    if item is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Позиция не найдена"
        )
    await session.delete(item)
    await session.commit()
