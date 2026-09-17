from datetime import datetime, timezone

from sqlalchemy import String, DateTime, ForeignKey, Numeric
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Pago(Base):
    __tablename__ = "pagos"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    pedido_id: Mapped[int] = mapped_column(
        ForeignKey("pedidos.id"),
        nullable=False
    )

    metodo: Mapped[str] = mapped_column(
        String(30),
        nullable=False
    )

    monto: Mapped[float] = mapped_column(
        Numeric(10, 2),
        nullable=False
    )

    estado: Mapped[str] = mapped_column(
        String(30),
        default="pendiente",
        nullable=False
    )

    referencia: Mapped[str | None] = mapped_column(
        String(150),
        nullable=True
    )

    fecha_pago: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True
    )
