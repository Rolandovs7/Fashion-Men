"""
[Segundo Parcial] CU11 - Gestionar reservas
"""
from datetime import datetime, timezone

from sqlalchemy import String, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Reserva(Base):
    """
    [Segundo Parcial] CU11 - Gestionar reservas
    """
    __tablename__ = "reservas"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    usuario_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id"),
        nullable=False
    )

    sucursal_id: Mapped[int] = mapped_column(
        ForeignKey("sucursales.id"),
        nullable=False
    )

    empresa_id: Mapped[int | None] = mapped_column(
        ForeignKey("empresas.id"),
        nullable=True,
        index=True
    )

    fecha_reserva: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False
    )

    estado: Mapped[str] = mapped_column(
        String(30),
        default="pendiente",
        nullable=False
    )

    observaciones: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True
    )

    detalles = relationship("DetalleReserva", backref="reserva", cascade="all, delete-orphan")

