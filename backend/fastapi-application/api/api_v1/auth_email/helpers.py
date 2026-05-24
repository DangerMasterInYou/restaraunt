from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.config import settings
from core.models import User, Token


async def token_count_check(
    user: User,
    session: AsyncSession,
    max_tokens: int = settings.auth_jwt.max_token_count,
):
    """Проверяет количество активных токенов пользователя и удаляет старые при превышении лимита"""
    stmt = select(Token).where(Token.user_id == user.id).order_by(Token.created_at)
    active_tokens = await session.scalars(stmt)
    active_tokens = active_tokens.all()

    if len(active_tokens) >= max_tokens:
        # Удаляем самые старые токены, оставляя (max_tokens - 1) токенов
        # чтобы освободить место для нового
        tokens_to_delete = active_tokens[: len(active_tokens) - (max_tokens - 1)]
        for token in tokens_to_delete:
            await session.delete(token)

        await session.commit()
