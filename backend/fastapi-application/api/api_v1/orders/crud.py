import re
from datetime import datetime
from typing import List, Optional


def _with_order_param(return_url: str, order_id: int) -> str:
    """Добавляет ?paid_order=<id> к return_url, чтобы клиент после оплаты
    автоматически подтвердил заказ и попал на его страницу (#5)."""
    sep = "&" if "?" in (return_url or "") else "?"
    return f"{return_url}{sep}paid_order={order_id}"
from fastapi import HTTPException, status
from sqlalchemy import select, delete as sa_delete
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload, joinedload
from core.models import (
    Order, OrderItem, OrderStatusEnum, Payment, PaymentStatusEnum, OrderStatusHistory,
    CartItem, CartItemModifiersAssociation, ProductVariant, Modifier, Product, User
)
from core.orders_ws import active_orders_ws_manager
from core.services import yookassa
from api.api_v1.promotions.discounts import compute_cart_discount
from .schemas import OrderCreateRequest, OrderItemUpdateRequest, OrderResponse

ACTIVE_ORDER_STATUSES = (
    OrderStatusEnum.AWAITING_CONFIRMATION,
    OrderStatusEnum.COOKING,
    OrderStatusEnum.READY_FOR_PICKUP,
)

ONLINE_PAYMENT_METHODS = {"card", "online", "sbp", "yookassa", "online_card"}


def _is_online_method(method: Optional[str]) -> bool:
    return (method or "").lower() in ONLINE_PAYMENT_METHODS


async def _notify_active_orders_ws(session: AsyncSession) -> None:
    orders = await get_active_orders(session)
    payload = [
        OrderResponse.model_validate(order).model_dump(mode="json") for order in orders
    ]
    await active_orders_ws_manager.broadcast(payload)

async def _get_order_by_id(order_id: int, session: AsyncSession, for_user_id: Optional[int] = None) -> Order:
    query = select(Order).where(Order.id == order_id)
    if for_user_id is not None:
        query = query.where(Order.user_id == for_user_id)
    query = query.options(
        selectinload(Order.items).selectinload(OrderItem.product_variant).joinedload(ProductVariant.product),
        selectinload(Order.payment),
        selectinload(Order.status_history)
    )
    result = await session.execute(query)
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Заказ не найден.")
    return order

async def _recalculate_total_price(order: Order, session: AsyncSession) -> int:
    total = 0
    for item in order.items:
        variant = await session.get(ProductVariant, item.product_variant_id)
        if variant:
            total += variant.price * item.quantity
    return total

async def create_order_from_cart(
    user_id: int, order_data: OrderCreateRequest, session: AsyncSession
):
    """Создаёт заказ из корзины и очищает её.

    #8: для онлайн-оплаты платёж ЮKassa создаётся АТОМАРНО — до очистки корзины
    и коммита. Если ЮKassa недоступна/ошибка — откатываем: заказ НЕ создаётся,
    корзина остаётся. Возвращает кортеж (order, confirmation_url|None).
    """
    cart_items_query = (
        select(CartItem)
        .where(CartItem.user_id == user_id)
        .options(
            selectinload(CartItem.modifier_details).joinedload(CartItemModifiersAssociation.modifier),
            joinedload(CartItem.product_variant).joinedload(ProductVariant.product),
        )
    )
    cart_items = (await session.execute(cart_items_query)).scalars().all()
    if not cart_items:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Корзина пуста.")

    total_price = 0
    order_items = []
    line_items = []
    for item in cart_items:
        base_price = item.product_variant.price
        modifiers_price = sum(
            mod.modifier.price_delta * mod.quantity for mod in item.modifier_details
        )
        price_per_unit = base_price + modifiers_price
        total_price += price_per_unit * item.quantity

        _product = item.product_variant.product
        line_items.append({
            "category_id": _product.category_id if _product else None,
            "product_id": item.product_variant.product_id,
            "subtotal": price_per_unit * item.quantity,
        })

        applied_modifiers = [
            {
                "modifier_id": mod.modifier_id,
                "name": mod.modifier.name,
                "quantity": mod.quantity,
                "price_delta": mod.modifier.price_delta,
            }
            for mod in item.modifier_details
        ]
        order_items.append(OrderItem(
            product_variant_id=item.product_variant.id,
            quantity=item.quantity,
            price_per_unit=price_per_unit,
            applied_modifiers=applied_modifiers,
        ))

    _user = await session.get(User, user_id)
    discount, _ = await compute_cart_discount(
        session, line_items, user_birthday=_user.birthday if _user else None
    )
    total_price = max(0, total_price - discount)

    order_number = f"ORD-{user_id}-{int(datetime.now().timestamp())}"

    new_order = Order(
        user_id=user_id,
        status=OrderStatusEnum.AWAITING_CONFIRMATION,
        customer_name=order_data.customer_name,
        customer_phone=order_data.customer_phone,
        comment=order_data.comment,
        total_price=total_price,
        order_number=order_number,
    )
    new_order.items = order_items
    new_order.payment = Payment(
        amount=total_price,
        status=PaymentStatusEnum.PENDING,
        payment_system=order_data.payment_method,
    )
    new_order.status_history = [OrderStatusHistory(status=OrderStatusEnum.AWAITING_CONFIRMATION)]

    session.add(new_order)

    is_online = _is_online_method(order_data.payment_method)
    confirmation_url = None
    if is_online:
        if not yookassa.is_configured():
            await session.rollback()
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=(
                    "ЮKassa не настроена: укажите APP_CONFIG__API_YOOKASSA__SHOP_ID "
                    "и секретный ключ. Заказ не создан."
                ),
            )
        await session.flush()
        try:
            data = await yookassa.create_payment(
                total_price,
                f"Заказ {order_number}",
                new_order.id,
                _with_order_param(
                    order_data.return_url or "https://example.com/return",
                    new_order.id,
                ),
            )
            confirmation_url = (data.get("confirmation") or {}).get(
                "confirmation_url"
            )
            if not confirmation_url:
                raise RuntimeError("ЮKassa не вернула ссылку для оплаты")
        except Exception as exc:
            await session.rollback()
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Оплата не создана: {exc}. Заказ не оформлен.",
            )
        new_order.payment.transaction_id = data.get("id")

    if not is_online:
        for item in cart_items:
            await session.delete(item)

    await session.commit()
    await _notify_active_orders_ws(session)
    order = await _get_order_by_id(new_order.id, session)
    return order, confirmation_url


async def create_order_direct(
    operator_user_id: int, data, session: AsyncSession
) -> Order:
    """#FE18: заказ, созданный оператором напрямую из позиций (не из корзины)."""
    if not data.items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Пустой заказ."
        )

    total_price = 0
    order_items = []
    line_items = []
    for item_data in data.items:
        variant = await session.get(ProductVariant, item_data.product_variant_id)
        if not variant:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Вариант продукта ID {item_data.product_variant_id} не найден.",
            )
        price_per_unit = variant.price
        applied_modifiers = []
        if item_data.modifier_ids:
            modifiers = (
                await session.execute(
                    select(Modifier).where(Modifier.id.in_(item_data.modifier_ids))
                )
            ).scalars().all()
            price_per_unit += sum(m.price_delta for m in modifiers)
            applied_modifiers = [
                {
                    "modifier_id": m.id,
                    "name": m.name,
                    "quantity": 1,
                    "price_delta": m.price_delta,
                }
                for m in modifiers
            ]
        total_price += price_per_unit * item_data.quantity
        _product = await session.get(Product, variant.product_id)
        line_items.append({
            "category_id": _product.category_id if _product else None,
            "product_id": variant.product_id,
            "subtotal": price_per_unit * item_data.quantity,
        })
        order_items.append(OrderItem(
            product_variant_id=item_data.product_variant_id,
            quantity=item_data.quantity,
            price_per_unit=price_per_unit,
            applied_modifiers=applied_modifiers,
        ))

    _bday = None
    if data.customer_phone:
        _client = await session.scalar(
            select(User).where(User.phone == data.customer_phone)
        )
        _bday = _client.birthday if _client else None
    discount, _ = await compute_cart_discount(
        session, line_items, user_birthday=_bday
    )
    total_price = max(0, total_price - discount)

    order_number = f"OP-{operator_user_id}-{int(datetime.now().timestamp())}"
    is_paid_online = _is_online_method(data.payment_method)

    new_order = Order(
        user_id=operator_user_id,
        status=OrderStatusEnum.AWAITING_CONFIRMATION,
        customer_name=data.customer_name,
        customer_phone=data.customer_phone,
        comment=data.comment,
        total_price=total_price,
        order_number=order_number,
    )
    new_order.items = order_items
    new_order.payment = Payment(
        amount=total_price,
        status=PaymentStatusEnum.SUCCESSFUL
        if is_paid_online
        else PaymentStatusEnum.PENDING,
        payment_system=data.payment_method,
    )
    new_order.status_history = [
        OrderStatusHistory(
            status=OrderStatusEnum.AWAITING_CONFIRMATION,
            note="Заказ создан оператором",
        )
    ]
    session.add(new_order)
    await session.commit()
    await _notify_active_orders_ws(session)
    return await _get_order_by_id(new_order.id, session)


async def get_orders_for_user(user_id: int, session: AsyncSession) -> List[Order]:
    query = (
        select(Order)
        .where(Order.user_id == user_id)
        .options(
            selectinload(Order.items).selectinload(OrderItem.product_variant).joinedload(ProductVariant.product),
            selectinload(Order.payment),
            selectinload(Order.status_history)
        )
        .order_by(Order.created_at.desc())
    )
    result = await session.execute(query)
    return result.scalars().unique().all()

async def get_order_details_for_user(user_id: int, order_id: int, session: AsyncSession) -> Order:
    return await _get_order_by_id(order_id, session, for_user_id=user_id)


async def get_order_by_number_for_user(
    user_id: int, order_number: str, session: AsyncSession
) -> Order:
    """#3: получить заказ клиента по человекочитаемому order_number (для URL
    /orders/{order_number})."""
    query = (
        select(Order)
        .where(Order.order_number == order_number, Order.user_id == user_id)
        .options(
            selectinload(Order.items)
            .selectinload(OrderItem.product_variant)
            .joinedload(ProductVariant.product),
            selectinload(Order.payment),
            selectinload(Order.status_history),
        )
    )
    order = (await session.execute(query)).scalar_one_or_none()
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Заказ не найден."
        )
    return order

async def get_all_orders(session: AsyncSession, status_filter: Optional[str] = None) -> List[Order]:
    query = select(Order).options(
        selectinload(Order.items).selectinload(OrderItem.product_variant).joinedload(ProductVariant.product),
        selectinload(Order.payment),
        selectinload(Order.status_history)
    )
    if status_filter:
        try:
            status_enum = OrderStatusEnum[status_filter]
        except KeyError:
            try:
                status_enum = OrderStatusEnum(status_filter)
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Некорректный статус: {status_filter}",
                )
        query = query.where(Order.status == status_enum)
    query = query.order_by(Order.created_at.desc())
    result = await session.execute(query)
    return result.scalars().unique().all()


async def get_active_orders(session: AsyncSession) -> List[Order]:
    """Активные (не архивные) заказы для оператора и WebSocket."""
    query = (
        select(Order)
        .where(Order.status.in_(ACTIVE_ORDER_STATUSES))
        .options(
            selectinload(Order.items).selectinload(OrderItem.product_variant).joinedload(ProductVariant.product),
            selectinload(Order.payment),
            selectinload(Order.status_history),
        )
        .order_by(Order.created_at.desc())
    )
    result = await session.execute(query)
    return result.scalars().unique().all()

async def update_order_status(order_id: int, new_status_str: str, session: AsyncSession) -> Order:
    order = await _get_order_by_id(order_id, session)
    try:
        new_status = OrderStatusEnum(new_status_str)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Некорректный статус: {new_status_str}")

    if order.status == new_status:
        return order

    if new_status == OrderStatusEnum.COMPLETED:
        paid = (
            order.payment.amount
            if (order.payment
                and order.payment.status == PaymentStatusEnum.SUCCESSFUL)
            else 0
        )
        if paid < (order.total_price or 0):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Нельзя завершить заказ: он не оплачен полностью.",
            )

    order.status = new_status
    order.status_history.append(OrderStatusHistory(
        status=new_status,
        note=f"Статус изменён на «{new_status.value}»",
    ))
    await session.commit()
    await _notify_active_orders_ws(session)
    return await _get_order_by_id(order_id, session)

async def update_order_items(
    order_id: int,
    items_data: List[OrderItemUpdateRequest],
    session: AsyncSession,
    payment_method: Optional[str] = None,
) -> Order:
    order = await _get_order_by_id(order_id, session)

    if order.status in [OrderStatusEnum.COMPLETED, OrderStatusEnum.CANCELLED]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Запрещено редактировать архивные или отмененные заказы"
        )

    def _composition_sig(items):
        sig = []
        for it in items:
            mods = tuple(sorted(
                m.get("modifier_id") for m in (it.applied_modifiers or [])
            ))
            sig.append((it.product_variant_id, it.quantity, mods))
        return sorted(sig)

    old_sig = _composition_sig(order.items)
    old_total = order.total_price

    def _item_label(product_name, variant_name, mod_names):
        label = f"{product_name} ({variant_name})"
        if mod_names:
            label += " +" + ", ".join(mod_names)
        return label

    old_counts: dict[str, int] = {}
    for it in order.items:
        pv = it.product_variant
        mod_names = sorted(
            (m.get("name") or "")
            for m in (it.applied_modifiers or [])
            if m.get("name")
        )
        pname = pv.product.name if pv and pv.product else "?"
        vname = pv.name if pv else "?"
        label = _item_label(pname, vname, mod_names)
        old_counts[label] = old_counts.get(label, 0) + it.quantity
    new_counts: dict[str, int] = {}

    for item in order.items:
        await session.delete(item)
    order.items = []

    new_items = []
    total_price = 0
    line_items = []

    for item_data in items_data:
        variant = await session.get(ProductVariant, item_data.product_variant_id)
        if not variant:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Вариант продукта ID {item_data.product_variant_id} не найден."
            )

        price_per_unit = variant.price
        applied_modifiers = []
        if item_data.modifier_ids:
            modifiers = await session.execute(
                select(Modifier).where(Modifier.id.in_(item_data.modifier_ids))
            )
            modifiers = modifiers.scalars().all()
            price_per_unit += sum(m.price_delta for m in modifiers)
            applied_modifiers = [
                {
                    "modifier_id": m.id,
                    "name": m.name,
                    "quantity": 1,
                    "price_delta": m.price_delta,
                }
                for m in modifiers
            ]

        total_price += price_per_unit * item_data.quantity

        _prod = await session.get(Product, variant.product_id)
        line_items.append({
            "category_id": _prod.category_id if _prod else None,
            "product_id": variant.product_id,
            "subtotal": price_per_unit * item_data.quantity,
        })
        _mod_names = sorted(m["name"] for m in applied_modifiers)
        _label = _item_label(
            _prod.name if _prod else "?", variant.name, _mod_names
        )
        new_counts[_label] = new_counts.get(_label, 0) + item_data.quantity

        new_items.append(OrderItem(
            order_id=order_id,
            product_variant_id=item_data.product_variant_id,
            quantity=item_data.quantity,
            price_per_unit=price_per_unit,
            applied_modifiers=applied_modifiers,
        ))

    _bday = None
    if order.customer_phone:
        _client = await session.scalar(
            select(User).where(User.phone == order.customer_phone)
        )
        _bday = _client.birthday if _client else None
    discount, _applied = await compute_cart_discount(
        session, line_items, user_birthday=_bday
    )
    total_price = max(0, total_price - discount)

    order.items = new_items
    order.total_price = total_price

    was_paid = (
        order.payment is not None
        and order.payment.status == PaymentStatusEnum.SUCCESSFUL
    )
    paid_amount = order.payment.amount if order.payment else 0
    gap_note = None
    if order.payment:
        if payment_method:
            order.payment.payment_system = payment_method
        if was_paid:
            gap = total_price - paid_amount
            if gap > 0:
                gap_note = (
                    f"Требуется доплата {gap} ₽ "
                    f"(новая сумма {total_price} ₽, оплачено {paid_amount} ₽)"
                )
            elif gap < 0:
                gap_note = (
                    f"К возврату разница {-gap} ₽ "
                    f"(новая сумма {total_price} ₽, оплачено {paid_amount} ₽)"
                )
        else:
            order.payment.amount = total_price

    composition_changed = (
        _composition_sig(new_items) != old_sig or total_price != old_total
    )
    if composition_changed:
        added, removed = [], []
        for label in set(old_counts) | set(new_counts):
            delta = new_counts.get(label, 0) - old_counts.get(label, 0)
            if delta > 0:
                added.append(f"{label} ×{delta}")
            elif delta < 0:
                removed.append(f"{label} ×{-delta}")
        parts = []
        if added:
            parts.append("Добавлено: " + ", ".join(sorted(added)))
        if removed:
            parts.append("Убрано: " + ", ".join(sorted(removed)))
        detail = "; ".join(parts) if parts else "состав обновлён"
        note = f"{detail}. Сумма {total_price} ₽"
        if gap_note:
            note += f". {gap_note}"
        order.status_history.append(OrderStatusHistory(
            status=order.status,
            note=note,
        ))

    await session.commit()
    await _notify_active_orders_ws(session)
    return await _get_order_by_id(order_id, session)

async def set_birthday_discount(
    order_id: int, enabled: bool, session: AsyncSession
) -> Order:
    """#5: оператор включает/выключает скидку в день рождения для НЕоплаченного
    заказа. Пересчитывает сумму (forced birthday on/off в движке скидок)."""
    order = await _get_order_by_id(order_id, session)
    if order.status in (OrderStatusEnum.COMPLETED, OrderStatusEnum.CANCELLED):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Нельзя менять скидку для архивного заказа.",
        )
    if order.payment and order.payment.status == PaymentStatusEnum.SUCCESSFUL:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Заказ уже оплачен — скидку изменить нельзя.",
        )

    line_items = []
    subtotal = 0
    for it in order.items:
        pv = it.product_variant
        prod = pv.product if pv else None
        sub = (it.price_per_unit or 0) * it.quantity
        subtotal += sub
        line_items.append({
            "category_id": prod.category_id if prod else None,
            "product_id": pv.product_id if pv else None,
            "subtotal": sub,
        })

    forced_birthday = datetime.now().date() if enabled else None
    discount, _ = await compute_cart_discount(
        session, line_items, user_birthday=forced_birthday
    )
    order.total_price = max(0, subtotal - discount)
    if order.payment:
        order.payment.amount = order.total_price

    note = (
        "Скидка в день рождения включена"
        if enabled
        else "Скидка в день рождения отключена"
    ) + f". Сумма {order.total_price} ₽"
    order.status_history.append(
        OrderStatusHistory(status=order.status, note=note)
    )
    await session.commit()
    await _notify_active_orders_ws(session)
    return await _get_order_by_id(order_id, session)


async def mark_order_paid(order_id: int, session: AsyncSession) -> Order:
    """Помечает заказ оплаченным (имитация успешной оплаты / оплата наличными).

    #11: при отметке оплаты закрываем кассовый разрыв — оплаченная сумма
    становится равной текущей сумме заказа (это покрывает и доплату).
    """
    order = await _get_order_by_id(order_id, session)
    if order.payment is None:
        order.payment = Payment(
            amount=order.total_price,
            status=PaymentStatusEnum.SUCCESSFUL,
            payment_system="cash",
        )
    else:
        order.payment.status = PaymentStatusEnum.SUCCESSFUL
        order.payment.amount = order.total_price
    order.status_history.append(OrderStatusHistory(
        status=order.status,
        note="Заказ оплачен",
    ))
    await session.commit()
    await _notify_active_orders_ws(session)
    return await _get_order_by_id(order_id, session)


async def mark_cash_paid(order_id: int, session: AsyncSession) -> Order:
    """#2: оператор отмечает оплату наличными.

    Способ оплаты фиксируется ФАКТИЧЕСКОЙ оплатой, а не выбором при оформлении:
    пока заказ не оплачен — можно оплатить как наличными, так и онлайн. Но если
    заказ уже оплачен ОНЛАЙН — доплата наличными запрещена (смешивать нельзя)."""
    order = await _get_order_by_id(order_id, session)
    if (
        order.payment
        and order.payment.status == PaymentStatusEnum.SUCCESSFUL
        and _is_online_method(order.payment.payment_system)
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Заказ уже оплачен онлайн: доплата вносится только онлайн "
                "клиентом."
            ),
        )
    if order.payment and not _is_online_method(order.payment.payment_system):
        order.payment.payment_system = order.payment.payment_system or "cash"
    return await mark_order_paid(order_id, session)


async def create_payment_session(
    order_id: int, session: AsyncSession, return_url: str
) -> dict:
    """#5/#6: создаёт реальный платёж ЮKassa и возвращает confirmation_url
    для редиректа клиента на платёжную страницу."""
    order = await _get_order_by_id(order_id, session)

    if (
        order.payment
        and order.payment.status == PaymentStatusEnum.SUCCESSFUL
        and not _is_online_method(order.payment.payment_system)
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Заказ уже оплачен наличными: доплата принимается только "
                "наличными у оператора."
            ),
        )

    paid = (
        order.payment.amount
        if (order.payment and order.payment.status == PaymentStatusEnum.SUCCESSFUL)
        else 0
    )
    due = (order.total_price or 0) - paid
    if due <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Заказ уже оплачен — доплата не требуется.",
        )

    if order.payment is None:
        order.payment = Payment(
            amount=order.total_price,
            status=PaymentStatusEnum.PENDING,
            payment_system="yookassa",
        )

    if not yookassa.is_configured():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "ЮKassa не настроена: укажите APP_CONFIG__API_YOOKASSA__SHOP_ID "
                "и секретный ключ."
            ),
        )

    try:
        data = await yookassa.create_payment(
            due,
            f"Заказ {order.order_number}",
            order_id,
            _with_order_param(return_url, order_id),
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Ошибка создания платежа ЮKassa: {exc}",
        )

    order.payment.transaction_id = data.get("id")
    order.payment.payment_system = "yookassa"
    if order.payment.status != PaymentStatusEnum.SUCCESSFUL:
        order.payment.status = PaymentStatusEnum.PENDING
    await session.commit()

    confirmation_url = (data.get("confirmation") or {}).get("confirmation_url")
    if not confirmation_url:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="ЮKassa не вернула ссылку для оплаты.",
        )
    return {
        "confirmation_url": confirmation_url,
        "payment_id": data.get("id"),
        "amount": due,
    }


async def confirm_payment(order_id: int, session: AsyncSession) -> Order:
    """#6: подтверждение оплаты по статусу платежа ЮKassa (нужно для локального
    теста, где вебхук не достаёт до localhost). Помечает заказ оплаченным,
    если ЮKassa вернула статус succeeded."""
    order = await _get_order_by_id(order_id, session)
    if (
        order.payment
        and order.payment.status == PaymentStatusEnum.SUCCESSFUL
        and (order.payment.amount or 0) >= (order.total_price or 0)
    ):
        return order
    payment_id = order.payment.transaction_id if order.payment else None
    if not payment_id or not yookassa.is_configured():
        return order
    try:
        data = await yookassa.get_payment(payment_id)
    except Exception:
        return order
    if data.get("status") == "succeeded":
        result = await mark_order_paid(order_id, session)
        await session.execute(
            sa_delete(CartItem).where(CartItem.user_id == order.user_id)
        )
        await session.commit()
        return result
    return order


def _already_refunded(order) -> int:
    """#5: суммарно возвращённая сумма по записям истории (нотам с «возврат N ₽»)."""
    total = 0
    for h in order.status_history or []:
        note = (h.note or "").lower()
        if "возврат" in note:
            m = re.search(r"возврат\s+(\d+)", note)
            if m:
                total += int(m.group(1))
    return total


async def refund_order(
    order_id: int, session: AsyncSession, amount: Optional[int] = None
) -> Order:
    """#7/#8: возврат средств. amount=None → полный возврат остатка.

    Для онлайн-оплаты (ЮKassa) вызывается реальный refund API; для наличных —
    только отметка в системе. Полный возврат отменяет заказ.
    """
    order = await _get_order_by_id(order_id, session)
    if order.payment is None or order.payment.status not in (
        PaymentStatusEnum.SUCCESSFUL,
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Возврат невозможен: заказ не оплачен.",
        )
    already_refunded = _already_refunded(order)
    remaining = order.payment.amount - already_refunded
    if remaining <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Заказ уже полностью возвращён.",
        )
    refund_amount = amount if amount is not None else remaining
    if refund_amount <= 0 or refund_amount > remaining:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Нельзя вернуть больше остатка ({remaining} ₽).",
        )

    payment_system = (order.payment.payment_system or "").lower()
    is_online = payment_system in {"yookassa", "online", "card", "sbp"}
    if is_online and order.payment.transaction_id and yookassa.is_configured():
        try:
            await yookassa.create_refund(
                order.payment.transaction_id, refund_amount
            )
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"ЮKassa отклонила возврат: {exc}",
            )

    is_full = refund_amount == remaining
    if is_full:
        order.payment.status = PaymentStatusEnum.REFUNDED
        order.status = OrderStatusEnum.CANCELLED
        note = f"Полный возврат {refund_amount} ₽, заказ отменён"
    else:
        note = (
            f"Частичный возврат {refund_amount} ₽ "
            f"(остаток {remaining - refund_amount} ₽)"
        )
    order.status_history.append(
        OrderStatusHistory(status=order.status, note=note)
    )
    await session.commit()
    await _notify_active_orders_ws(session)
    return await _get_order_by_id(order_id, session)


async def delete_order(order_id: int, session: AsyncSession) -> None:
    order = await _get_order_by_id(order_id, session)
    await session.delete(order)
    await session.commit()
    await _notify_active_orders_ws(session)
