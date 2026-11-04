"""
[Segundo Parcial] CU10 - Gestionar ventas presenciales
[Segundo Parcial] CU13 - Carrito y Pedidos
"""
"""
[Segundo Parcial] CU20 - Sincronización offline
[Segundo Parcial] CU21 - Resolución de conflictos de stock
"""
from datetime import datetime, timezone

from sqlalchemy import String, DateTime, ForeignKey, Numeric
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Pedido(Base):
    """
    [Segundo Parcial] CU10 - Gestionar ventas presenciales
    [Segundo Parcial] CU13 - Gestionar carrito y pedidos
    [Segundo Parcial] CU20 - Sincronización offline
    [Segundo Parcial] CU21 - Resolución de conflictos de stock
    """
    __tablename__ = "pedidos"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    usuario_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id"),
        nullable=False
    )

    sucursal_id: Mapped[int | None] = mapped_column(
        ForeignKey("sucursales.id"),
        nullable=True
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

    fecha_pedido: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        nullable=False
    )

    estado: Mapped[str] = mapped_column(
        String(50),
        default="pendiente",
        nullable=False
    )

    total: Mapped[float] = mapped_column(
        Numeric(10, 2),
        default=0,
        nullable=False
    )

    detalles = relationship("DetallePedido", backref="pedido", cascade="all, delete-orphan")

