"""Первоначальное наполнение базы данных меню.

Содержит РЕАЛЬНЫЕ данные меню (категории, продукты, варианты, группы
модификаторов, модификаторы, связи и комбо-наборы).

Сидинг идемпотентный: данные добавляются ТОЛЬКО если таблица категорий пуста.
Объекты создаются через ORM-отношения (без явных первичных ключей), поэтому
последовательности (sequences) PostgreSQL остаются корректными, и последующие
вставки через админ-панель не будут конфликтовать по id.

Запуск выполняется автоматически на старте приложения (см. main.py -> lifespan),
а также может быть вызван вручную:

    python -m scripts.seed_data
"""

from __future__ import annotations

import asyncio

from datetime import date

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from core.models import (
    Category,
    Product,
    ProductVariant,
    ModifierGroup,
    Modifier,
    ComboBundle,
    Promotion,
    PromotionType,
    PromotionTargetType,
)

_SEED_TABLES = (Category, Product, ProductVariant, ModifierGroup, Modifier, ComboBundle)

_TRANSLIT = {
    "а": "a", "б": "b", "в": "v", "г": "g", "д": "d", "е": "e", "ё": "e",
    "ж": "zh", "з": "z", "и": "i", "й": "i", "к": "k", "л": "l", "м": "m",
    "н": "n", "о": "o", "п": "p", "р": "r", "с": "s", "т": "t", "у": "u",
    "ф": "f", "х": "h", "ц": "c", "ч": "ch", "ш": "sh", "щ": "sch",
    "ъ": "", "ы": "y", "ь": "", "э": "e", "ю": "yu", "я": "ya",
}


def _slug(name: str) -> str:
    out = []
    for ch in name.lower():
        if ch in _TRANSLIT:
            out.append(_TRANSLIT[ch])
        elif ch.isalnum():
            out.append(ch)
        elif ch in " -_":
            out.append("_")
    slug = "".join(out).strip("_")
    while "__" in slug:
        slug = slug.replace("__", "_")
    return slug or "item"


def _img(name: str) -> str:
    return f"/static/images/{_slug(name)}.jpg"


def _variant(
    name: str,
    price: int,
    sku: str,
    *,
    value: int | None = None,
    unit: str | None = None,
    is_combo: bool = False,
    description: str | None = None,
) -> ProductVariant:
    return ProductVariant(
        name=name,
        price=price,
        sku=sku,
        value=value,
        unit=unit,
        is_available=True,
        is_combo=is_combo,
        description=description,
        image_url=None,
    )


def _product(
    name: str,
    description: str,
    sort_order: int,
    category: Category,
    variants: list[ProductVariant],
) -> Product:
    return Product(
        name=name,
        description=description or name,
        sort_order=sort_order,
        image_url=_img(name),
        category=category,
        variants=variants,
    )


def build_seed_objects() -> list[object]:
    """Создаёт полный граф ORM-объектов меню."""

    cat_shaurma = Category(name="Шаурма", sort_order=1)
    cat_doner = Category(name="Донер", sort_order=2)
    cat_hotdog = Category(name="Хот-дог", sort_order=3)
    cat_burger = Category(name="Бургер", sort_order=4)
    cat_drinks = Category(name="Напитки", sort_order=5)
    cat_coffee = Category(name="Кофе", sort_order=6)
    cat_snacks = Category(name="Закуски", sort_order=7)
    cat_combo = Category(name="Комбо", sort_order=8)

    group_addons = ModifierGroup(
        name="Добавки",
        is_required=False,
        is_multiselect=True,
        modifiers=[
            Modifier(name="Сыр", price_delta=30),
            Modifier(name="Морковь по-корейски", price_delta=30),
            Modifier(name="Огурец маринованный", price_delta=30),
            Modifier(name="Картофель жареный", price_delta=30),
            Modifier(name="Перец халапеньо", price_delta=30),
            Modifier(name="Грибы жареные", price_delta=30),
            Modifier(name="Кукуруза", price_delta=30),
            Modifier(name="Лук фрайс", price_delta=30),
            Modifier(name="Яйцо", price_delta=30),
            Modifier(name="Дополнительное мясо", price_delta=50),
        ],
    )
    group_sauces = ModifierGroup(
        name="Соусы",
        is_required=False,
        is_multiselect=True,
        modifiers=[
            Modifier(name="Сырный", price_delta=30),
            Modifier(name="Барбекю", price_delta=30),
            Modifier(name="Чесночный", price_delta=30),
            Modifier(name="Кетчуп", price_delta=30),
            Modifier(name="Острый", price_delta=30),
        ],
    )
    group_coffee_addons = ModifierGroup(
        name="Добавка к кофе",
        is_required=False,
        is_multiselect=True,
        modifiers=[
            Modifier(name="Сироп в ассортименте", price_delta=40),
            Modifier(name="Сливки", price_delta=40),
        ],
    )
    group_plant_milk = ModifierGroup(
        name="Растительное молоко",
        is_required=False,
        is_multiselect=False,
        modifiers=[
            Modifier(name="Кокосовое", price_delta=60),
            Modifier(name="Миндальное", price_delta=60),
            Modifier(name="Банановое", price_delta=60),
        ],
    )

    food_groups = [group_addons, group_sauces]
    coffee_groups = [group_coffee_addons, group_plant_milk]

    for _grp in (group_addons, group_sauces, group_coffee_addons, group_plant_milk):
        for _mod in _grp.modifiers:
            _mod.image_url = _img(_mod.name)

    shaurma_specs = [
        (
            "Шаурма классическая",
            190,
            "Лаваш малый, соус авторский, морковь по-корейски, помидор свежий, "
            "огурец свежий, курица",
        ),
        (
            "Шаурма деревенская",
            220,
            "Лаваш малый, соус авторский, морковь по-корейски, огурец маринованный, "
            "картошка фри, помидор свежий, курица",
        ),
        (
            "Шаурма вегетарианская",
            150,
            "Лаваш малый, соус авторский, помидоры свежие, огурцы свежие, "
            "морковь по-корейски, картошка фри",
        ),
        (
            "Шаурма большой Русский",
            220,
            "Лаваш малый, соус авторский, помидоры свежие, огурцы свежие, "
            "морковь по-корейски, картошка фри, курица",
        ),
        (
            "Шаурма богатырь",
            350,
            "Лаваш большой, соус авторский, картофель жареный, огурец свежий, "
            "морковь по-корейски, помидор свежий, курица",
        ),
        (
            "Шаурма большая",
            250,
            "Лаваш большой, соус авторский, морковь по-корейски, помидор свежий, "
            "огурец свежий, курица",
        ),
        (
            "Шаурма барбекю",
            220,
            "Сырный лаваш, курица, сосиска жареная, картошка фри, огурец свежий, "
            "соус барбекю, авторский соус",
        ),
        (
            "Шаурма с говядиной",
            250,
            "Лаваш малый, соус авторский, помидоры свежие, огурцы свежие, "
            "морковь по-корейски, говядина",
        ),
        (
            "Шаурма сырная",
            220,
            "Сырный лаваш, сыр чеддар, помидор свежий, картошка фри, огурец свежий, "
            "соус авторский, курица",
        ),
        (
            "Шаурма острая",
            220,
            "Лаваш малый, соус авторский, соус острый, халапеньо, "
            "морковь по-корейски, помидор свежий, огурец свежий, курица",
        ),
    ]
    shaurma_products = []
    for idx, (name, price, desc) in enumerate(shaurma_specs, start=1):
        sku = f"SHW-{idx:02d}"
        shaurma_products.append(
            _product(name, desc, idx, cat_shaurma, [_variant("Стандарт", price, sku)])
        )

    doner_product = _product(
        "Донер",
        "Донер круглый, соус авторский, огурец свежий, помидор свежий, говядина",
        1,
        cat_doner,
        [_variant("Стандарт", 250, "DNR-01")],
    )

    hotdog_product = _product(
        "Хот-дог Нью-Йоркский",
        "Булка хот-дог, соус авторский, кетчуп, сосиска, горчица, "
        "огурец маринованный, морковь по-корейски",
        1,
        cat_hotdog,
        [_variant("Стандарт", 150, "HTD-01")],
    )

    burger_product = _product(
        "Бургер из мраморной говядины",
        "Фарш универсальный, огурец маринованный, помидор свежий, сыр чеддар, "
        "айсберг, соус барбекю, булка для бургера",
        1,
        cat_burger,
        [_variant("Стандарт", 300, "BRG-01")],
    )

    cola_330 = _variant("0.33 л", 80, "DRK-COLA-033", value=330, unit="мл")
    cola_500 = _variant("0.5 л", 100, "DRK-COLA-05", value=500, unit="мл")
    cola_product = _product(
        "Кока-кола", "Классическая Coca-Cola", 1, cat_drinks, [cola_330, cola_500]
    )
    water_product = _product(
        "Вода",
        "Питьевая вода",
        2,
        cat_drinks,
        [
            _variant("0.5 л", 50, "DRK-WTR-05", value=500, unit="мл"),
            _variant("1 л", 100, "DRK-WTR-1", value=1000, unit="мл"),
        ],
    )

    raf_v = _variant("0.3 л", 250, "COF-RAF-03", value=300, unit="мл")
    latte_v = _variant("0.3 л", 250, "COF-LAT-03", value=300, unit="мл")
    cap_200 = _variant("0.2 л", 180, "COF-CAP-02", value=200, unit="мл")
    cap_300 = _variant("0.3 л", 250, "COF-CAP-03", value=300, unit="мл")
    raf_product = _product("Раф", "Нежный кофейный напиток", 1, cat_coffee, [raf_v])
    latte_product = _product("Латте", "Кофе с молоком", 2, cat_coffee, [latte_v])
    cappuccino_product = _product(
        "Капучино", "Кофе с молочной пенкой", 3, cat_coffee, [cap_200, cap_300]
    )

    fries_std = _variant("Стандарт", 120, "SNC-FRY-STD", value=100, unit="гр")
    fries_big = _variant("Большой", 150, "SNC-FRY-BIG", value=150, unit="гр")
    fries_product = _product(
        "Картофель фри",
        "Хрустящий картофель фри",
        1,
        cat_snacks,
        [fries_std, fries_big],
    )
    nuggets_4 = _variant("4 шт", 80, "SNC-NUG-4", value=60, unit="гр")
    nuggets_7 = _variant("7 шт", 140, "SNC-NUG-7", value=100, unit="гр")
    nuggets_product = _product(
        "Наггетсы", "Куриные наггетсы", 2, cat_snacks, [nuggets_4, nuggets_7]
    )

    shaurma_classic_v = shaurma_products[0].variants[0]
    hitbox_v = _variant("Стандарт", 410, "CMB-HIT", is_combo=True)
    hitbox = _product(
        "Хит-Бокс",
        "Шаурма классическая + Картофель фри + Кока-кола 0.33 л",
        1,
        cat_combo,
        [hitbox_v],
    )
    hotdog_combo_v = _variant("Стандарт", 350, "CMB-HTD", is_combo=True)
    hotdog_combo = _product(
        "Хот-Дог комбо",
        "Хот-дог Нью-Йоркский + Картофель фри + Кока-кола 0.33 л",
        2,
        cat_combo,
        [hotdog_combo_v],
    )
    kids_v = _variant("Стандарт", 190, "CMB-KIDS", is_combo=True)
    kids_combo = _product(
        "Детское",
        "Наггетсы (4 шт) + Картофель фри + соус на выбор",
        3,
        cat_combo,
        [kids_v],
    )
    burger_box_v = _variant("Стандарт", 450, "CMB-BRG", is_combo=True)
    burger_box = _product(
        "Бургер бокс",
        "Бургер из мраморной говядины + Картофель фри + Кока-кола 0.33 л",
        4,
        cat_combo,
        [burger_box_v],
    )

    burger_v = burger_product.variants[0]
    hotdog_v = hotdog_product.variants[0]

    combo_bundles = [
        ComboBundle(
            combo_variant=hitbox_v, included_variant=shaurma_classic_v, quantity=1
        ),
        ComboBundle(combo_variant=hitbox_v, included_variant=fries_std, quantity=1),
        ComboBundle(combo_variant=hitbox_v, included_variant=cola_330, quantity=1),
        ComboBundle(
            combo_variant=hotdog_combo_v, included_variant=hotdog_v, quantity=1
        ),
        ComboBundle(
            combo_variant=hotdog_combo_v, included_variant=fries_std, quantity=1
        ),
        ComboBundle(
            combo_variant=hotdog_combo_v, included_variant=cola_330, quantity=1
        ),
        ComboBundle(combo_variant=kids_v, included_variant=nuggets_4, quantity=1),
        ComboBundle(combo_variant=kids_v, included_variant=fries_std, quantity=1),
        ComboBundle(combo_variant=burger_box_v, included_variant=burger_v, quantity=1),
        ComboBundle(combo_variant=burger_box_v, included_variant=fries_std, quantity=1),
        ComboBundle(combo_variant=burger_box_v, included_variant=cola_330, quantity=1),
    ]

    food_variants = [p.variants[0] for p in shaurma_products] + [
        doner_product.variants[0],
        hotdog_v,
        burger_v,
    ]
    for variant in food_variants:
        variant.modifier_groups.extend(food_groups)

    for variant in (raf_v, latte_v, cap_200, cap_300):
        variant.modifier_groups.extend(coffee_groups)

    kids_v.modifier_groups.append(group_sauces)

    all_products = (
        shaurma_products
        + [doner_product, hotdog_product, burger_product]
        + [cola_product, water_product]
        + [raf_product, latte_product, cappuccino_product]
        + [fries_product, nuggets_product]
        + [hitbox, hotdog_combo, kids_combo, burger_box]
    )

    objects: list[object] = [
        cat_shaurma,
        cat_doner,
        cat_hotdog,
        cat_burger,
        cat_drinks,
        cat_coffee,
        cat_snacks,
        cat_combo,
        group_addons,
        group_sauces,
        group_coffee_addons,
        group_plant_milk,
    ]
    objects.extend(all_products)
    objects.extend(combo_bundles)
    return objects


async def seed_initial_data(session: AsyncSession) -> bool:
    """Наполняет БД, если она пуста. Возвращает True, если данные были добавлены.

    Проверяет содержимое ВСЕХ ключевых таблиц меню (категории, продукты,
    варианты, группы модификаторов, модификаторы, комбо). Если хотя бы одна из
    них уже содержит данные — сидинг пропускается, чтобы не задвоить меню.
    """
    for model in _SEED_TABLES:
        count = await session.scalar(select(func.count()).select_from(model))
        if count and count > 0:
            return False

    session.add_all(build_seed_objects())
    await session.commit()

    await _seed_promotions(session)
    return True


async def _seed_promotions(session: AsyncSession) -> None:
    """Создаёт акции по умолчанию (#10 — именинникам на шаурму 10%,
    #11 — −500 ₽ по выходным июля 2026 при заказе от 3000 ₽)."""
    existing = await session.scalar(select(func.count()).select_from(Promotion))
    if existing and existing > 0:
        return

    shaurma = await session.scalar(
        select(Category).where(Category.name == "Шаурма")
    )

    promos = [
        Promotion(
            title="Именинникам",
            description="Скидка 10% на всю шаурму в день рождения",
            discount_label="-10%",
            promo_type=PromotionType.percent,
            discount_value=10,
            target_type=PromotionTargetType.category,
            target_id=shaurma.id if shaurma else None,
            is_active=False,
        ),
        Promotion(
            title="Выходные июля",
            description="−500 ₽ при заказе от 3000 ₽ по сб и вс с 15:00 до 16:00",
            discount_label="-500 ₽",
            promo_type=PromotionType.fixed,
            discount_value=500,
            min_order_amount=3000,
            target_type=PromotionTargetType.all,
            start_date=date(2026, 7, 1),
            end_date=date(2026, 7, 31),
            start_time="15:00",
            end_time="16:00",
            days_of_week="5,6",
            is_active=True,
        ),
    ]
    session.add_all(promos)
    await session.commit()


_DEFAULT_ADMIN_EMAIL = "imoddinov@gmail.com"


async def ensure_first_user_admin(session: AsyncSession) -> None:
    """#1: гарантируем наличие админа imoddinov@gmail.com.

    Авторизация по коду из почты (без пароля), поэтому создаём пользователя
    только с email и ролью admin. Если такой email уже есть — повышаем до
    admin; если нет — создаём.
    """
    from core.models import User
    from core.models.user import UserRole

    try:
        existing = await session.scalar(
            select(User).where(User.email == _DEFAULT_ADMIN_EMAIL)
        )
        if existing is None:
            session.add(User(email=_DEFAULT_ADMIN_EMAIL, role=UserRole.admin))
        elif existing.role != UserRole.admin:
            existing.role = UserRole.admin
        await session.commit()
    except Exception:
        await session.rollback()


import os

_IMAGES_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "static",
    "images",
)


def _file_exists(url: str | None) -> bool:
    if not url:
        return False
    return os.path.exists(os.path.join(_IMAGES_DIR, os.path.basename(url)))


async def backfill_image_urls(session: AsyncSession) -> None:
    """#1: чинит image_url для уже наполненной БД (сид не перезапускается).

    Если текущий путь пуст / placeholder / указывает на несуществующий файл —
    подставляем /static/images/<slug имени>.jpg, НО только если такой файл
    реально существует. Рабочие (загруженные) картинки не трогаем.
    """
    try:
        products = (await session.scalars(select(Product))).all()
        for p in products:
            if not _file_exists(p.image_url):
                candidate = _img(p.name)
                if _file_exists(candidate):
                    p.image_url = candidate
        modifiers = (await session.scalars(select(Modifier))).all()
        for m in modifiers:
            if not _file_exists(m.image_url):
                candidate = _img(m.name)
                if _file_exists(candidate):
                    m.image_url = candidate
        await session.commit()
    except Exception:
        await session.rollback()


async def _main() -> None:
    from core.db_helper import db_helper

    async with db_helper.session_factory() as session:
        created = await seed_initial_data(session)
    print("Данные меню добавлены." if created else "БД уже содержит данные — пропуск.")
    await db_helper.dispose()


if __name__ == "__main__":
    asyncio.run(_main())
