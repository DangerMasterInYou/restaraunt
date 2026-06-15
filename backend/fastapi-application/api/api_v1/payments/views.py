"""Эндпоинты оплаты.

Реализована ИМИТАЦИЯ оплаты (по заданию): онлайн-оплата подтверждается сразу
при создании заказа, а наличные клиент может оплатить после создания заказа
через `POST /payments/{order_id}/pay`. Также есть webhook-эндпоинт под формат
уведомлений YooKassa — он помечает заказ оплаченным при событии
`payment.succeeded`.
"""

from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Path, Request
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from core.db_helper import db_helper
from core.services.check_policy import require_operator_or_admin
from api.api_v1.orders import crud as orders_crud
from api.api_v1.orders.schemas import OrderResponse

router = APIRouter(prefix="/payments", tags=["Payments"])

_RETURN_PAGE = """<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Оплата завершена</title>
<style>
  html,body{height:100%;margin:0}
  body{display:flex;align-items:center;justify-content:center;
    font-family:-apple-system,Roboto,Segoe UI,Arial,sans-serif;
    background:#0f172a;color:#e2e8f0;padding:24px;box-sizing:border-box}
  .card{max-width:420px;text-align:center;background:#1e293b;border-radius:20px;
    padding:32px 24px;box-shadow:0 10px 30px rgba(0,0,0,.35)}
  .check{width:72px;height:72px;border-radius:50%;background:#16a34a;margin:0 auto 16px;
    display:flex;align-items:center;justify-content:center;font-size:40px;color:#fff}
  h1{font-size:20px;margin:0 0 8px}
  p{font-size:15px;line-height:1.5;color:#cbd5e1;margin:0}
  .hint{margin-top:18px;font-size:13px;color:#94a3b8}
</style>
</head>
<body>
  <div class="card">
    <div class="check">&#10003;</div>
    <h1>Оплата обрабатывается</h1>
    <p>Закройте эту вкладку браузера и вернитесь в приложение —
       статус заказа обновится автоматически.</p>
    <div class="hint">Можно закрывать эту страницу.</div>
  </div>
</body>
</html>"""


@router.get("/return", response_class=HTMLResponse)
async def payment_return():
    """Страница возврата после оплаты (для мобильных): просит закрыть браузер и
    вернуться в приложение. Лёгкая локальная страница вместо внешнего example.com,
    из-за которого браузер на устройстве зависал."""
    return HTMLResponse(_RETURN_PAGE)


class PaymentInitRequest(BaseModel):
    return_url: Optional[str] = None


class PaymentInitResponse(BaseModel):
    confirmation_url: str
    payment_id: str
    amount: int


class RefundRequest(BaseModel):
    """amount=None → полный возврат; иначе частичный."""
    amount: Optional[int] = None


@router.post("/{order_id}/init", response_model=PaymentInitResponse)
async def init_payment(
    order_id: Annotated[int, Path],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    body: Optional[PaymentInitRequest] = None,
):
    """#5/#6: создаёт платёж ЮKassa и возвращает confirmation_url для редиректа."""
    return_url = (body.return_url if body else None) or "https://example.com/return"
    return await orders_crud.create_payment_session(order_id, session, return_url)


@router.post("/{order_id}/confirm", response_model=OrderResponse)
async def confirm_payment(
    order_id: Annotated[int, Path],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """#6: проверить статус платежа в ЮKassa и подтвердить заказ (для случаев,
    когда вебхук не доходит до localhost). Безопасно вызывать повторно."""
    return await orders_crud.confirm_payment(order_id, session)


@router.post("/{order_id}/pay", response_model=OrderResponse)
async def pay_order(
    order_id: Annotated[int, Path],
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    _=Depends(require_operator_or_admin),
):
    """#6: оператор/админ отмечает оплату наличными (при выдаче) как успешную.
    #2: запрещено для онлайн-заказов (их оплачивает клиент через ЮKassa)."""
    return await orders_crud.mark_cash_paid(order_id, session)


@router.post("/{order_id}/refund", response_model=OrderResponse)
async def refund_payment(
    order_id: Annotated[int, Path],
    body: RefundRequest,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    _=Depends(require_operator_or_admin),
):
    """Slice C: возврат средств (оператор/админ). Полный или частичный."""
    return await orders_crud.refund_order(order_id, session, amount=body.amount)


@router.post("/yookassa/webhook")
async def yookassa_webhook(
    request: Request,
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
):
    """Webhook YooKassa. Ожидает JSON вида
    {"event": "payment.succeeded", "object": {"metadata": {"order_id": N}}}."""
    try:
        body = await request.json()
    except Exception:
        return {"ok": False, "detail": "invalid json"}

    event = body.get("event", "")
    obj = body.get("object") or {}
    metadata = obj.get("metadata") or {}
    order_id = metadata.get("order_id")

    if event == "payment.succeeded" and order_id is not None:
        try:
            await orders_crud.mark_order_paid(int(order_id), session)
        except Exception as exc:
            return {"ok": False, "detail": str(exc)}
    return {"ok": True}
