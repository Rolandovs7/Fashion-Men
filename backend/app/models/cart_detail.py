from sqlalchemy import ForeignKey, Integer
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class DetalleCarrito(Base):
    __tablename__ = "detalles_carrito"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    carrito_id: Mapped[int] = mapped_column(
        ForeignKey("carritos.id"),
        nullable=False
    )

    variante_id: Mapped[int] = mapped_column(
        ForeignKey("producto_variantes.id"),
        nullable=False
    )

    cantidad: Mapped[int] = mapped_column(
        Integer,
        default=1,
        nullable=False
    )
