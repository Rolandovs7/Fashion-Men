from datetime import date

from sqlalchemy import String, Boolean, Numeric, Date
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Descuento(Base):
    __tablename__ = "descuentos"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    nombre: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )

    porcentaje: Mapped[float] = mapped_column(
        Numeric(5, 2),
        nullable=False
    )

    fecha_inicio: Mapped[date | None] = mapped_column(
        Date,
        nullable=True
    )

    fecha_fin: Mapped[date | None] = mapped_column(
        Date,
        nullable=True
    )

    activo: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )
