import os
import asyncio
from contextlib import asynccontextmanager
from datetime import datetime, timedelta
from enum import Enum
import random
from typing import List

import uvicorn
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import ORJSONResponse
from starlette.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from core.config import settings
from api import router as api_router
from core.db_helper import db_helper


STATIC_DIR = "static"
IMAGES_DIR = os.path.join(STATIC_DIR, "images")
os.makedirs(IMAGES_DIR, exist_ok=True)
# ------------------------------------


@asynccontextmanager
async def lifespan(app: FastAPI):
    # startup
    yield
    # shutdown
    await db_helper.dispose()


main_app = FastAPI(
    lifespan=lifespan,
    default_response_class=ORJSONResponse,
)
main_app.include_router(router=api_router)


main_app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")

main_app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@main_app.get("/")
async def root():
    return {"message": "Hello, World and FastAPI!"}


class Status(str, Enum):
    created = "created"
    rejected = "rejected"
    accepted = "accepted"
    ready = "ready"
    issued = "issued"


class Order:
    def __init__(
        self,
        order_id: int,
        user_id: int,
        items_products: str,
        payment_method: str,
        payed: bool,
        status: Status,
        created_at: str,
        created_by: str,
        updated_at: str,
        updated_by: str,
    ):
        self.id = order_id
        self.user_id = user_id
        self.items_products = items_products
        self.payment_method = payment_method
        self.payed = payed
        self.status = status
        self.created_at = created_at
        self.created_by = created_by
        self.updated_at = updated_at
        self.updated_by = updated_by

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "items_products": self.items_products,
            "payment_method": self.payment_method,
            "payed": self.payed,
            "status": self.status.value,
            "created_at": self.created_at,
            "created_by": self.created_by,
            "updated_at": self.updated_at,
            "updated_by": self.updated_by,
        }


product_names = [
    "Эспрессо",
    "Капучино",
    "Кока-Кола",
    "Пепси",
    "Чай черный",
    "Чай зеленый",
    "Шоколадный милкшейк",
    "Ванильный милкшейк",
    "Шаурма с курицей",
    "Шаурма с говядиной",
    "Классический хот-дог",
    "Чили-дог",
    "Картофель фри",
    "Наггетсы куриные",
    "Куриные стрипсы",
    "Комбо меню",
]


def get_orders_sample() -> List[Order]:
    now = datetime.utcnow()
    statuses = [Status.created, Status.rejected, Status.accepted, Status.ready]
    orders = []

    for i in range(10):
        status = statuses[i % len(statuses)]

        # Генерация случайных продуктов в заказе
        num_products = random.randint(1, 4)
        products = random.sample(product_names, num_products)
        items_products = ", ".join(products)

        # Генерация случайных значений для других полей
        payment_method = random.choice(["cash", "card", "online"])
        payed = random.choice([True, False])
        user_id = 100 + i
        created_by = f"user{user_id}"
        updated_by = f"user{user_id}"

        # Создание заказа
        order = Order(
            order_id=i + 1,
            user_id=user_id,
            items_products=items_products,
            payment_method=payment_method,
            payed=payed,
            status=status,
            created_at=(now - timedelta(minutes=i * 3)).isoformat(),
            created_by=created_by,
            updated_at=(now - timedelta(minutes=i * 2)).isoformat(),
            updated_by=updated_by,
        )
        orders.append(order)

    return orders


@main_app.websocket("/orders/active/ws")
async def orders_active_ws(websocket: WebSocket):
    await websocket.accept()
    print("Клиент подключился")
    try:
        # Отправляем данные сразу при подключении
        orders = get_orders_sample()
        orders_list = [
            order.to_dict() for order in orders if order.status != Status.issued
        ]
        await websocket.send_json(orders_list)
        print(f"Отправлено {len(orders_list)} заказов при подключении")

        # Затем продолжаем отправлять каждые 30 секунд
        while True:
            await asyncio.sleep(30)
            orders = get_orders_sample()
            orders_list = [
                order.to_dict() for order in orders if order.status != Status.issued
            ]
            await websocket.send_json(orders_list)
            print(f"Отправлено {len(orders_list)} заказов (периодическое обновление)")
    except WebSocketDisconnect:
        print("Клиент отключился")
    except Exception as e:
        print(f"Ошибка в WebSocket: {str(e)}")

#Start
if __name__ == "__main__":
    uvicorn.run(
        app=settings.run.app,
        host=settings.run.host,
        port=settings.run.port,
        reload=settings.run.reload,
        ws="websockets",
    )
