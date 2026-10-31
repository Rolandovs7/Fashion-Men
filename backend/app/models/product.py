"""
[Segundo Parcial] CU06 - Gestionar catálogo
[Segundo Parcial] CU27 - Gestionar listas de precios
[Segundo Parcial] RF01 - Aislamiento Multitenant
"""
from sqlalchemy import String, Text, Boolean, Numeric, ForeignKey, Integer, Float
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Producto(Base):
    """
    [Segundo Parcial] CU06 - Gestionar catálogo
    [Segundo Parcial] CU27 - Gestionar listas de precios
    """
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

    imagen_url: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    modelo_ar_url: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    precio: Mapped[float] = mapped_column(
        Numeric(10, 2),
        nullable=False
    )

    precio_mayorista: Mapped[float | None] = mapped_column(
        Numeric(10, 2),
        nullable=True
    )

    cantidad_mayorista: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True
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

    empresa_id: Mapped[int | None] = mapped_column(
        ForeignKey("empresas.id"),
        nullable=True,
        index=True
    )

    activo: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )
