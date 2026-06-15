import enum
from datetime import date

from sqlalchemy import String, Text, Integer, Boolean, Date, Enum, text
from sqlalchemy.orm import Mapped, mapped_column

from core.models import Base
from core.models.mixins import IntIdPkMixin
from core.models.mixins.timestamp import TimestampMixin


class PromotionType(str, enum.Enum):
    percent = "percent"
    fixed = "fixed"
    bundle = "bundle"


class PromotionTargetType(str, enum.Enum):
    all = "all"
    category = "category"
    product = "product"


class Promotion(IntIdPkMixin, TimestampMixin, Base):
    """Акция/скидка, настраиваемая администратором.

    Условия активности: диапазон дат, диапазон времени суток (например 19:00–20:00)
    и дни недели. Применение к цене корзины не выполняется — модель служит для
    описания и красивого отображения акций в меню.
    """

    __tablename__ = "promotions"

    title: Mapped[str] = mapped_column(String(120))
    description: Mapped[str | None] = mapped_column(Text)

    discount_label: Mapped[str | None] = mapped_column(String(60))

    promo_type: Mapped[PromotionType] = mapped_column(
        Enum(PromotionType), default=PromotionType.percent
    )
    discount_value: Mapped[int | None] = mapped_column(Integer)

    min_order_amount: Mapped[int | None] = mapped_column(Integer)

    target_type: Mapped[PromotionTargetType] = mapped_column(
        Enum(PromotionTargetType), default=PromotionTargetType.all
    )
    target_id: Mapped[int | None] = mapped_column(Integer)

    start_date: Mapped[date | None] = mapped_column(Date)
    end_date: Mapped[date | None] = mapped_column(Date)
    start_time: Mapped[str | None] = mapped_column(String(5))
    end_time: Mapped[str | None] = mapped_column(String(5))
    days_of_week: Mapped[str | None] = mapped_column(String(20))

    is_active: Mapped[bool] = mapped_column(
        Boolean, default=True, server_default=text("TRUE")
    )

    is_birthday: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default=text("FALSE")
    )
