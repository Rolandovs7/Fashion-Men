from sqlalchemy import ForeignKey, Integer
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Inventario(Base):
    __tablename__ = "inventarios"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    variante_id: Mapped[int] = mapped_column(
        ForeignKey("producto_variantes.id"),
        nullable=False
    )

    sucursal_id: Mapped[int] = mapped_column(
        ForeignKey("sucursales.id"),
        nullable=False
    )

    cantidad: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False
    )

    cantidad_reservada: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False
    )
