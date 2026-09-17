from sqlalchemy import ForeignKey, Integer, Numeric
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class DetallePedido(Base):
    __tablename__ = "detalles_pedido"

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

    precio_unitario: Mapped[float] = mapped_column(
        Numeric(10, 2),
        nullable=False
    )

    subtotal: Mapped[float] = mapped_column(
        Numeric(10, 2),
        nullable=False
    )
