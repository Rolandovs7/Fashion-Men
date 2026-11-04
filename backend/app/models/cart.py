"""
[Segundo Parcial] CU13 - Registrarse como cliente y comprar
"""
from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Carrito(Base):
    """
    [Segundo Parcial] CU13 - Registrarse como cliente y comprar
    """
    __tablename__ = "carritos"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    usuario_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id"),
        nullable=False
    )

    empresa_id: Mapped[int | None] = mapped_column(
        ForeignKey("empresas.id"),
        nullable=True,
        index=True
    )

    detalles = relationship("DetalleCarrito", backref="carrito", cascade="all, delete-orphan")

