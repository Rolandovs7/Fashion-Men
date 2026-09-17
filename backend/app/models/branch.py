from sqlalchemy import String, Boolean
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Sucursal(Base):
    __tablename__ = "sucursales"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    nombre: Mapped[str] = mapped_column(
        String(100),
        unique=True,
        nullable=False
    )

    direccion: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )

    ciudad: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )

    telefono: Mapped[str | None] = mapped_column(
        String(30),
        nullable=True
    )

    activo: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )
