# Файл: api/admin/menu/modifier/schemas.py (Рекомендую создать новую папку и файл)

from typing import List, Optional
from pydantic import BaseModel, ConfigDict

# ===================================================================
# СХЕМЫ ДЛЯ УПРАВЛЕНИЯ МОДИФИКАТОРАМИ И ИХ ГРУППАМИ
# ===================================================================


# --- Схемы для Модификатора (опции внутри группы) ---
class ModifierResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    price_delta: int


class ModifierCreate(BaseModel):
    name: str
    price_delta: int = 0


class ModifierUpdate(BaseModel):
    name: Optional[str] = None
    price_delta: Optional[int] = None


# --- Схемы для Группы Модификаторов ---
class ModifierGroupResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    is_required: bool
    is_multiselect: bool
    is_deleted: bool
    modifiers: List[ModifierResponse]


class ModifierGroupCreate(BaseModel):
    name: str
    is_required: bool = False
    is_multiselect: bool = True
    # # Группа создается сразу со списком своих опций
    # modifiers: List[ModifierCreate]


class ModifierGroupUpdate(BaseModel):
    name: Optional[str] = None
    is_required: Optional[bool] = None
    is_multiselect: Optional[bool] = None


class ModifierGroupDeleteResponse(BaseModel):
    success: bool
    message: str


# Схема для управления связью
class AssociationResponse(BaseModel):
    success: bool
    message: str


class ModifierDeleteResponse(ModifierGroupDeleteResponse):
    pass
