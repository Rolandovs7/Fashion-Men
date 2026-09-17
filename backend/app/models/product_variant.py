from sqlalchemy import ForeignKey, Boolean
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class ProductoVariante(Base):
    __tablename__ = "producto_variantes"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    producto_id: Mapped[int] = mapped_column(
        ForeignKey("productos.id"),
        nullable=False
    )

    talla_id: Mapped[int] = mapped_column(
        ForeignKey("tallas.id"),
        nullable=False
    )

    color_id: Mapped[int] = mapped_column(
        ForeignKey("colores.id"),
        nullable=False
    )

    activo: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )
