import os
import shutil
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, status, Path
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.db_helper import db_helper
from core.models import Product

router = APIRouter(prefix="/products", tags=["Products"])

IMAGES_DIR = "static/images"

http_bearer = HTTPBearer()


@router.post("/upload-image")
async def upload_image(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(http_bearer)],
    file: UploadFile = File(...),
):
    """Универсальная загрузка картинки. Возвращает {"image_url": "/static/..."}.

    Используется формами админ-панели (продукт, вариант, модификатор) для
    смены изображения по нажатию (#19).
    """
    ext = (file.filename or "img.png").split(".")[-1]
    unique_filename = f"{uuid.uuid4()}.{ext}"
    file_path = os.path.join(IMAGES_DIR, unique_filename)
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    finally:
        file.file.close()
    return {"image_url": f"/static/images/{unique_filename}"}

@router.post(
    "/{product_id}/upload-image",
)
async def upload_product_image(
    session: Annotated[AsyncSession, Depends(db_helper.session_getter)],
    product_id: Annotated[int, Path],
credentials: Annotated[HTTPAuthorizationCredentials, Depends(http_bearer)],
    file: UploadFile = File(...),
):
    product: Product | None = await session.scalar(
        select(Product).where(Product.id == product_id)
    )
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with id {product_id} not found",
        )

    file_extension = file.filename.split(".")[-1]
    unique_filename = f"{uuid.uuid4()}.{file_extension}"
    file_path = os.path.join(IMAGES_DIR, unique_filename)

    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    finally:
        file.file.close()

    image_url_path = f"/static/images/{unique_filename}"
    product.image_url = image_url_path
    await session.commit()
    await session.refresh(product)

    return product
