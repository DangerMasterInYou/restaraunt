from typing import List
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from fastapi import HTTPException, status

from core.models import ModifierGroup, Modifier, ProductVariant

from .schemas import (
    ModifierGroupCreate,
    ModifierGroupUpdate,
    ModifierCreate,
    ModifierUpdate,
)

from ..product.crud import get_variant




async def get_modifier_group(session: AsyncSession, group_id: int) -> ModifierGroup:
    """
    Получает одну группу модификаторов по ID, включая все ее вложенные опции (модификаторы).
    """
    group: ModifierGroup | None = await session.get(
        ModifierGroup,
        group_id,
        options=[
            selectinload(ModifierGroup.modifiers)
        ],
    )
    if not group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Группа модификаторов с ID {group_id} не найдена.",
        )
    return group


async def check_for_existing_group_name(
    session: AsyncSession,
    name: str,
    exclude_id: int | None = None,
) -> None:
    """Вспомогательная функция для проверки уникальности имени группы."""
    query = select(ModifierGroup).where(ModifierGroup.name == name)
    if exclude_id:
        query = query.where(ModifierGroup.id != exclude_id)

    existing_group = await session.scalar(query)
    if existing_group:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Группа с именем '{name}' уже существует.",
        )


async def create_modifier_group(
    group_data: ModifierGroupCreate,
    session: AsyncSession,
) -> ModifierGroup:
    """
    Создает группу модификаторов и все ее вложенные опции в одной транзакции.
    """
    try:
        await check_for_existing_group_name(session, group_data.name)

        group_dict = group_data.model_dump(exclude={"modifiers"})
        new_group = ModifierGroup(**group_dict)
        session.add(new_group)

        await session.commit()
        await session.refresh(
            new_group, ["modifiers"]
        )
        return new_group
    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(status_code=500, detail=f"Ошибка при создании группы: {e}")


async def get_all_modifier_groups(session: AsyncSession) -> List[ModifierGroup]:
    """Получает список всех групп модификаторов (включая удаленные)."""
    result = await session.scalars(
        select(ModifierGroup)
        .options(selectinload(ModifierGroup.modifiers))
        .order_by(ModifierGroup.name)
    )
    return list(result.all())


async def update_modifier_group(
    group_id: int,
    group_update: ModifierGroupUpdate,
    session: AsyncSession,
) -> ModifierGroup:
    """Обновляет основную информацию о группе (не затрагивая ее опции)."""
    try:
        group = await get_modifier_group(session, group_id)
        if group.is_deleted:
            raise HTTPException(
                status.HTTP_404_NOT_FOUND,
                "Группа мягко удалена и не может быть изменена.",
            )

        update_data = group_update.model_dump(exclude_unset=True)

        if "name" in update_data:
            await check_for_existing_group_name(
                session, update_data["name"], exclude_id=group_id
            )

        for key, value in update_data.items():
            setattr(group, key, value)

        await session.commit()
        await session.refresh(group, ["modifiers"])
        return group
    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status_code=500, detail=f"Ошибка при обновлении группы: {e}"
        )


async def soft_delete_modifier_group(
    group_id: int,
    session: AsyncSession,
    deleted: bool,
):
    """Мягкое удаление или восстановление группы модификаторов."""
    try:
        group = await get_modifier_group(session, group_id)

        if group.is_deleted == deleted:
            state = "удалена" if deleted else "восстановлена"
            raise HTTPException(status.HTTP_400_BAD_REQUEST, f"Группа уже {state}.")

        group.is_deleted = deleted
        await session.commit()

        message = "Группа мягко удалена." if deleted else "Группа восстановлена."
        return {"success": True, "message": message}
    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(status_code=500, detail=f"Внутренняя ошибка: {e}")


async def hard_delete_modifier_group(group_id: int, session: AsyncSession):
    """Безвозвратное удаление группы и всех ее опций (через CASCADE)."""
    try:
        group = await get_modifier_group(session, group_id)
        await session.delete(group)
        await session.commit()
        return {
            "success": True,
            "message": "Группа и все ее опции удалены безвозвратно.",
        }
    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(status_code=500, detail=f"Внутренняя ошибка: {e}")




async def get_all_modifiers(session: AsyncSession) -> List[Modifier]:
    """Получает список всех существующих опций (модификаторов)."""
    result = await session.scalars(select(Modifier).order_by(Modifier.id))
    return list(result.all())


async def get_modifier(session: AsyncSession, modifier_id: int) -> Modifier:
    """Получает одну опцию (модификатор) по ее ID."""
    modifier: Modifier | None = await session.get(Modifier, modifier_id)
    if not modifier:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, f"Модификатор с ID {modifier_id} не найден."
        )
    return modifier


async def check_for_existing_modifier_name(
    session: AsyncSession, group_id: int, name: str, exclude_id: int | None = None
) -> None:
    """Проверяет уникальность имени модификатора ВНУТРИ его родительской группы."""
    query = select(Modifier).where(Modifier.group_id == group_id, Modifier.name == name)
    if exclude_id:
        query = query.where(Modifier.id != exclude_id)

    existing_modifier = await session.scalar(query)
    if existing_modifier:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Опция с именем '{name}' уже существует в этой группе.",
        )


async def add_modifier_to_group(
    group_id: int,
    modifier_data: ModifierCreate,
    session: AsyncSession,
) -> Modifier:
    """Добавляет новую опцию к уже существующей группе."""
    try:
        group = await get_modifier_group(session, group_id)
        if group.is_deleted:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST, "Нельзя добавить опцию в удаленную группу."
            )

        await check_for_existing_modifier_name(session, group_id, modifier_data.name)

        new_modifier = Modifier(group_id=group_id, **modifier_data.model_dump())
        session.add(new_modifier)
        await session.commit()
        await session.refresh(new_modifier)
        return new_modifier
    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка при добавлении опции: {e}",
        )


async def update_modifier(
    modifier_id: int,
    modifier_update: ModifierUpdate,
    session: AsyncSession,
) -> Modifier:
    """Обновляет одну конкретную опцию (модификатор)."""
    try:
        modifier = await get_modifier(session, modifier_id)
        if modifier.is_deleted:
            raise HTTPException(
                status.HTTP_404_NOT_FOUND,
                "Модификатор мягко удален и не может быть изменен.",
            )

        update_data = modifier_update.model_dump(exclude_unset=True)

        if "name" in update_data:
            await check_for_existing_modifier_name(
                session=session,
                group_id=modifier.group_id,
                name=update_data["name"],
                exclude_id=modifier_id,
            )

        for key, value in update_data.items():
            setattr(modifier, key, value)

        await session.commit()
        await session.refresh(modifier)
        return modifier
    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(status_code=500, detail=f"Ошибка при обновлении опции: {e}")


async def soft_delete_modifier(
    modifier_id: int,
    session: AsyncSession,
    deleted: bool,
):
    """Мягкое удаление или восстановление одной опции (модификатора)."""
    try:
        modifier = await get_modifier(session, modifier_id)

        if modifier.is_deleted == deleted:
            state = "удален" if deleted else "восстановлен"
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Модификатор уже находится в состоянии '{state}'",
            )

        modifier.is_deleted = deleted
        await session.commit()

        message = (
            "Модификатор мягко удален." if deleted else "Модификатор восстановлен."
        )
        return {"success": True, "message": message}
    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Внутренняя ошибка: {e}"
        )


async def hard_delete_modifier(modifier_id: int, session: AsyncSession):
    """Безвозвратно удаляет одну конкретную опцию из группы."""
    try:
        modifier = await get_modifier(session, modifier_id)
        await session.delete(modifier)
        await session.commit()
        return {"success": True, "message": "Опция (модификатор) удалена безвозвратно."}
    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка при удалении опции: {e}",
        )




async def link_group_to_variant(variant_id: int, group_id: int, session: AsyncSession):
    """Применяет (привязывает) группу модификаторов к варианту продукта."""
    try:
        variant = await get_variant(
            session, variant_id
        )
        group = await get_modifier_group(session, group_id)

        if group.is_deleted:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST, "Нельзя применить удаленную группу."
            )
        if variant.is_deleted:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                "Нельзя применить группу к удаленному варианту.",
            )

        if group in variant.modifier_groups:
            raise HTTPException(
                status.HTTP_409_CONFLICT, "Эта группа уже применена к данному варианту."
            )

        variant.modifier_groups.append(group)
        await session.commit()
        return {"success": True, "message": "Группа успешно применена к варианту."}
    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Ошибка привязки группы: {e}"
        )


async def _product_variants(product_id: int, session: AsyncSession):
    result = await session.scalars(
        select(ProductVariant)
        .where(ProductVariant.product_id == product_id)
        .options(selectinload(ProductVariant.modifier_groups))
    )
    return list(result.all())


async def link_group_to_product(product_id: int, group_id: int, session: AsyncSession):
    """Применяет группу модификаторов ко ВСЕМ вариантам продукта (#FE14)."""
    try:
        group = await get_modifier_group(session, group_id)
        if group.is_deleted:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST, "Нельзя применить удаленную группу."
            )
        variants = await _product_variants(product_id, session)
        if not variants:
            raise HTTPException(
                status.HTTP_404_NOT_FOUND, "У продукта нет вариантов."
            )
        for variant in variants:
            if group not in variant.modifier_groups:
                variant.modifier_groups.append(group)
        await session.commit()
        return {"success": True, "message": "Группа применена ко всем вариантам."}
    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Ошибка привязки группы: {e}"
        )


async def unlink_group_from_product(
    product_id: int, group_id: int, session: AsyncSession
):
    """Убирает группу модификаторов у ВСЕХ вариантов продукта (#FE14)."""
    try:
        group = await get_modifier_group(session, group_id)
        variants = await _product_variants(product_id, session)
        for variant in variants:
            if group in variant.modifier_groups:
                variant.modifier_groups.remove(group)
        await session.commit()
        return {"success": True, "message": "Группа убрана у всех вариантов."}
    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Ошибка отвязки группы: {e}"
        )


async def unlink_group_from_variant(
    variant_id: int, group_id: int, session: AsyncSession
):
    """Убирает (отвязывает) группу модификаторов у варианта продукта."""
    try:
        variant = await session.get(
            ProductVariant,
            variant_id,
            options=[selectinload(ProductVariant.modifier_groups)],
        )
        if not variant:
            raise HTTPException(
                status.HTTP_404_NOT_FOUND, f"Вариант с ID {variant_id} не найден."
            )

        group = await get_modifier_group(
            session, group_id
        )

        if group not in variant.modifier_groups:
            raise HTTPException(
                status.HTTP_404_NOT_FOUND,
                "Эта группа не была применена к данному варианту.",
            )

        variant.modifier_groups.remove(group)
        await session.commit()
        return {"success": True, "message": "Группа успешно отвязана от варианта."}
    except HTTPException:
        await session.rollback()
        raise
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Ошибка отвязки группы: {e}"
        )
