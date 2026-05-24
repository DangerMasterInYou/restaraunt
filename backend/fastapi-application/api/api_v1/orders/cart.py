from fastapi import APIRouter

router = APIRouter()

@router.get("/cart")
async def get_cart():
    pass


@router.post("/cart/items")
async def add_cart():
    pass


@router.patch("/cart/items/{cart_item_id")
async def up_cart():
    pass


@router.delete("/cart/items/{cart_item_id")
async def delete_cart():
    pass