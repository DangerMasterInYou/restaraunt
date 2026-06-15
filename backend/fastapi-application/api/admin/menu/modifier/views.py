from typing import Annotated, List
from fastapi import APIRouter, Depends, Path, status
from fastapi.security import HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from core.db_helper import db_helper
from . import crud
from .schemas import (
    ModifierGroupCreate,
    ModifierGroupResponse,
    ModifierGroupUpdate,
    ModifierGroupDeleteResponse,
    AssociationResponse,
    ModifierResponse,
    ModifierCreate,
    ModifierUpdate,
    ModifierDeleteResponse,
)

router = APIRouter()



@router.post(
    "/modifier-groups",
    response_model=ModifierGroupResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Создать новую группу модификаторов",
)
async def create_modifier_group(
    group_data: ModifierGroupCreate,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Создает новую группу модификаторов (например, "Добавки") вместе
    со всеми ее опциями ("Сыр", "Халапеньо") в одной транзакции.
    """
    return await crud.create_modifier_group(session=session, group_data=group_data)


@router.get(
    "/modifier-groups",
    response_model=List[ModifierGroupResponse],
    summary="Получить список всех групп модификаторов",
)
async def get_all_modifier_groups(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Возвращает список всех групп модификаторов, включая их вложенные опции.
    """
    return await crud.get_all_modifier_groups(session=session)


@router.get(
    "/modifier-groups/{group_id}",
    response_model=ModifierGroupResponse,
    summary="Получить одну группу модификаторов по ID",
)
async def get_modifier_group(
    group_id: Annotated[int, Path(description="ID группы модификаторов")],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Возвращает детальную информацию о конкретной группе и ее опциях.
    """
    return await crud.get_modifier_group(session=session, group_id=group_id)


@router.patch(
    "/modifier-groups/{group_id}",
    response_model=ModifierGroupResponse,
    summary="Обновить группу модификаторов",
)
async def update_modifier_group(
    group_update: ModifierGroupUpdate,
    group_id: Annotated[int, Path(description="ID группы для обновления")],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Обновляет основную информацию о группе: название, обязательность выбора и т.д.
    Не затрагивает вложенные опции (модификаторы).
    """
    return await crud.update_modifier_group(
        group_id=group_id, group_update=group_update, session=session
    )


@router.delete(
    "/modifier-groups/{group_id}/soft",
    response_model=ModifierGroupDeleteResponse,
    summary="Мягкое удаление группы модификаторов",
)
async def soft_delete_modifier_group(
    group_id: Annotated[int, Path(description="ID группы для мягкого удаления")],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Помечает группу как удаленную, но не удаляет ее из базы данных.
    """
    return await crud.soft_delete_modifier_group(
        group_id=group_id, session=session, deleted=True
    )


@router.post(
    "/modifier-groups/{group_id}/restore",
    response_model=ModifierGroupDeleteResponse,
    summary="Восстановить мягко удаленную группу",
)
async def restore_modifier_group(
    group_id: Annotated[int, Path(description="ID группы для восстановления")],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Снимает пометку о мягком удалении с группы.
    """
    return await crud.soft_delete_modifier_group(
        group_id=group_id, session=session, deleted=False
    )


@router.delete(
    "/modifier-groups/{group_id}/hard",
    response_model=ModifierGroupDeleteResponse,
    summary="Безвозвратно удалить группу (опасно!)",
)
async def hard_delete_modifier_group(
    group_id: Annotated[int, Path(description="ID группы для полного удаления")],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Полностью удаляет группу и все связанные с ней опции из базы данных.
    Использовать с осторожностью.
    """
    return await crud.hard_delete_modifier_group(group_id=group_id, session=session)




@router.post(
    "/link/variants/{variant_id}/groups/{group_id}",
    response_model=AssociationResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Применить группу к варианту продукта",
)
async def link_group_to_variant(
    variant_id: Annotated[int, Path(description="ID варианта продукта")],
    group_id: Annotated[int, Path(description="ID группы модификаторов")],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Создает связь между вариантом продукта и группой модификаторов,
    делая опции этой группы доступными для выбора у данного товара.
    """
    return await crud.link_group_to_variant(
        variant_id=variant_id, group_id=group_id, session=session
    )


@router.delete(
    "/link/variants/{variant_id}/groups/{group_id}",
    response_model=AssociationResponse,
    summary="Отвязать группу от варианта продукта",
)
async def unlink_group_from_variant(
    variant_id: Annotated[int, Path(description="ID варианта продукта")],
    group_id: Annotated[int, Path(description="ID группы модификаторов")],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Удаляет связь между вариантом продукта и группой модификаторов.
    """
    return await crud.unlink_group_from_variant(
        variant_id=variant_id, group_id=group_id, session=session
    )


@router.post(
    "/link/products/{product_id}/groups/{group_id}",
    response_model=AssociationResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Применить группу ко всем вариантам продукта (#FE14)",
)
async def link_group_to_product(
    product_id: Annotated[int, Path(description="ID продукта")],
    group_id: Annotated[int, Path(description="ID группы модификаторов")],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.link_group_to_product(
        product_id=product_id, group_id=group_id, session=session
    )


@router.delete(
    "/link/products/{product_id}/groups/{group_id}",
    response_model=AssociationResponse,
    summary="Отвязать группу от всех вариантов продукта (#FE14)",
)
async def unlink_group_from_product(
    product_id: Annotated[int, Path(description="ID продукта")],
    group_id: Annotated[int, Path(description="ID группы модификаторов")],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    return await crud.unlink_group_from_product(
        product_id=product_id, group_id=group_id, session=session
    )




@router.get(
    "/modifiers",
    response_model=List[ModifierResponse],
    summary="Получить список всех опций (модификаторов)",
)
async def get_all_modifiers(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Возвращает плоский список всех существующих опций из всех групп.
    Полезно для поиска или справочников.
    """
    return await crud.get_all_modifiers(session=session)


@router.get(
    "/modifiers/{modifier_id}",
    response_model=ModifierResponse,
    summary="Получить одну опцию (модификатор) по ID",
)
async def get_modifier(
    modifier_id: Annotated[int, Path(description="ID конкретной опции")],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Возвращает информацию об одной конкретной опции (модификаторе).
    """
    return await crud.get_modifier(session=session, modifier_id=modifier_id)


@router.post(
    "/modifier-groups/{group_id}/modifiers",
    response_model=ModifierResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Добавить новую опцию (модификатор) в группу",
)
async def add_modifier_to_group(
    group_id: Annotated[int, Path(description="ID родительской группы")],
    modifier_data: ModifierCreate,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Создает новую опцию (например, "Сырный соус" с ценой 30) и привязывает
    ее к уже существующей группе модификаторов.
    """
    return await crud.add_modifier_to_group(
        group_id=group_id, modifier_data=modifier_data, session=session
    )


@router.patch(
    "/modifiers/{modifier_id}",
    response_model=ModifierResponse,
    summary="Обновить одну опцию (модификатор)",
)
async def update_modifier(
    modifier_update: ModifierUpdate,
    modifier_id: Annotated[int, Path(description="ID модификатора для обновления")],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Обновляет данные одной конкретной опции, например, ее название или цену.
    """
    return await crud.update_modifier(
        modifier_id=modifier_id, modifier_update=modifier_update, session=session
    )


@router.delete(
    "/modifiers/{modifier_id}/soft",
    response_model=ModifierDeleteResponse,
    summary="Мягкое удаление опции (модификатора)",
)
async def soft_delete_modifier(
    modifier_id: Annotated[
        int, Path(description="ID модификатора для мягкого удаления")
    ],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Помечает одну опцию как удаленную.
    """
    return await crud.soft_delete_modifier(
        modifier_id=modifier_id, session=session, deleted=True
    )


@router.post(
    "/modifiers/{modifier_id}/restore",
    response_model=ModifierDeleteResponse,
    summary="Восстановить мягко удаленную опцию",
)
async def restore_modifier(
    modifier_id: Annotated[int, Path(description="ID модификатора для восстановления")],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Снимает пометку о мягком удалении с одной опции.
    """
    return await crud.soft_delete_modifier(
        modifier_id=modifier_id, session=session, deleted=False
    )


@router.delete(
    "/modifiers/{modifier_id}/hard",
    response_model=ModifierDeleteResponse,
    summary="Безвозвратно удалить опцию (опасно!)",
)
async def hard_delete_modifier(
    modifier_id: Annotated[
        int, Path(description="ID модификатора для полного удаления")
    ],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """
    Полностью удаляет одну опцию (модификатор) из базы данных.
    """
    return await crud.hard_delete_modifier(modifier_id=modifier_id, session=session)
