import asyncio
import asyncpg

async def test_connection():
    try:
        conn = await asyncpg.connect(
            "postgresql://postgres:postgres@localhost:5432/dbfastfood"
        )
        print("✅ Прямое подключение через asyncpg успешно!")
        result = await conn.fetchval("SELECT version()")
        print(f"Версия PostgreSQL: {result}")
        await conn.close()
    except Exception as e:
        print(f"❌ Ошибка подключения: {e}")

asyncio.run(test_connection())
