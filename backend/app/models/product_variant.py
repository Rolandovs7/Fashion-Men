from sqlalchemy import ForeignKey, Boolean, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class ProductoVariante(Base):
    __tablename__ = "producto_variantes"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    producto_id: Mapped[int] = mapped_column(
        ForeignKey("productos.id"),
        nullable=False
    )

    talla_id: Mapped[int] = mapped_column(
        ForeignKey("tallas.id"),
        nullable=False
    )

    color_id: Mapped[int] = mapped_column(
        ForeignKey("colores.id"),
        nullable=False
    )

    nombre_variante: Mapped[str | None] = mapped_column(
        String(120),
        nullable=True
    )

    imagen_url: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    activo: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )

    # Relaciones eager-loaded para enriquecer inventarios sin N+1.
    producto: Mapped["Producto"] = relationship("Producto", lazy="joined")
    talla: Mapped["Talla"] = relationship("Talla", lazy="joined")
    color: Mapped["Color"] = relationship("Color", lazy="joined")
