"""
[Segundo Parcial] CU11 - Gestionar reservas
"""
"""
[Segundo Parcial] CU20 - Sincronización offline
[Segundo Parcial] CU21 - Resolución de conflictos de stock
"""
from datetime import datetime, timezone

from sqlalchemy import String, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Reserva(Base):
    """
    [Segundo Parcial] CU11 - Gestionar reservas
    [Segundo Parcial] CU20 - Sincronización offline
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

    uuid_offline: Mapped[str | None] = mapped_column(
        String(64),
        nullable=True,
        index=True
    )

    fecha_reserva: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False
    )

    estado: Mapped[str] = mapped_column(
        String(50),
        default="pendiente",
        nullable=False
    )

    observaciones: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True
    )

    detalles = relationship("DetalleReserva", backref="reserva", cascade="all, delete-orphan")

    # CU24 - Datos del cliente para las tablas de administración.
    cliente = relationship("Usuario", foreign_keys=[usuario_id])

