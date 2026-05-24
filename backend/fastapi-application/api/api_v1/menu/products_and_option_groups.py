from sqlalchemy import ForeignKey
from sqlalchemy.orm import mapped_column, Mapped

from core.models import Base


class ProductsAndOptionsGroups(Base):
    __tablename__ = "products_and_option_groups"
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"))
