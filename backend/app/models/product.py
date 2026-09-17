from sqlalchemy import String, Text, Boolean, Numeric, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Producto(Base):
    __tablename__ = "productos"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    nombre: Mapped[str] = mapped_column(
        String(150),
        nullable=False
    )

    descripcion: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )

    precio: Mapped[float] = mapped_column(
        Numeric(10, 2),
        nullable=False
    )

    categoria_id: Mapped[int] = mapped_column(
        ForeignKey("categorias.id"),
        nullable=False
    )

    proveedor_id: Mapped[int | None] = mapped_column(
        ForeignKey("proveedores.id"),
        nullable=True
    )

    temporada_id: Mapped[int | None] = mapped_column(
        ForeignKey("temporadas.id"),
        nullable=True
    )

    coleccion_id: Mapped[int | None] = mapped_column(
        ForeignKey("colecciones.id"),
        nullable=True
    )

    tipo_prenda_id: Mapped[int | None] = mapped_column(
        ForeignKey("tipos_prenda.id"),
        nullable=True
    )

    marca_id: Mapped[int | None] = mapped_column(
        ForeignKey("marcas.id"),
        nullable=True
    )

    descuento_id: Mapped[int | None] = mapped_column(
        ForeignKey("descuentos.id"),
        nullable=True
    )

    activo: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )
