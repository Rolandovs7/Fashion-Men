from datetime import datetime, timezone

from sqlalchemy import String, DateTime, ForeignKey, Numeric
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Pedido(Base):
    __tablename__ = "pedidos"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    usuario_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id"),
        nullable=False
    )

    fecha_pedido: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        nullable=False
    )

    estado: Mapped[str] = mapped_column(
        String(30),
        default="pendiente",
        nullable=False
    )

    total: Mapped[float] = mapped_column(
        Numeric(10, 2),
        default=0,
        nullable=False
    )

    detalles = relationship("DetallePedido", backref="pedido", cascade="all, delete-orphan")

