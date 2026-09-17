from datetime import datetime, timezone

from sqlalchemy import String, DateTime, ForeignKey, Integer
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Devolucion(Base):
    __tablename__ = "devoluciones"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    pedido_id: Mapped[int] = mapped_column(
        ForeignKey("pedidos.id"),
        nullable=False
    )

    variante_id: Mapped[int] = mapped_column(
        ForeignKey("producto_variantes.id"),
        nullable=False
    )

    cantidad: Mapped[int] = mapped_column(
        Integer,
        nullable=False
    )

    motivo: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )

    estado: Mapped[str] = mapped_column(
        String(30),
        default="pendiente",
        nullable=False
    )

    fecha_devolucion: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        nullable=False
    )
