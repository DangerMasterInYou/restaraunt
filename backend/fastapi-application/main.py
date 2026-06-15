import os
import asyncio
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import ORJSONResponse
from starlette.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from core.config import settings
from api import router as api_router
from core.db_helper import db_helper
from core.orders_ws import active_orders_ws_manager
from api.api_v1.orders.crud import get_active_orders
from api.api_v1.orders.schemas import OrderResponse

STATIC_DIR = "static"
IMAGES_DIR = os.path.join(STATIC_DIR, "images")
os.makedirs(IMAGES_DIR, exist_ok=True)


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        from scripts.seed_data import (
            seed_initial_data,
            ensure_first_user_admin,
            backfill_image_urls,
        )

        async with db_helper.session_factory() as session:
            created = await seed_initial_data(session)
            await ensure_first_user_admin(session)
            await backfill_image_urls(session)
        if created:
            print("Первоначальные данные меню добавлены в БД.")
    except Exception as exc:
        print(f"Сидинг данных пропущен из-за ошибки: {exc}")
    yield
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


@main_app.get("/tester")
async def tester():
    return {"message": "Hello, World and FastAPI!"}


async def _serialize_active_orders() -> list[dict]:
    async with db_helper.session_factory() as session:
        orders = await get_active_orders(session)
        return [
            OrderResponse.model_validate(order).model_dump(mode="json")
            for order in orders
        ]


@main_app.websocket("/orders/active/ws")
async def orders_active_ws(websocket: WebSocket):
    await active_orders_ws_manager.connect(websocket)
    try:
        await websocket.send_json(await _serialize_active_orders())
        while True:
            await asyncio.sleep(60)
    except WebSocketDisconnect:
        pass
    except Exception as e:
        print(f"Ошибка в WebSocket: {e}")
    finally:
        await active_orders_ws_manager.disconnect(websocket)


if __name__ == "__main__":
    uvicorn.run(
        app=settings.run.app,
        host=settings.run.host,
        port=settings.run.port,
        reload=settings.run.reload,
        ws="websockets",
    )
