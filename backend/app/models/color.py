from sqlalchemy import String, Boolean
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Color(Base):
    __tablename__ = "colores"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    nombre: Mapped[str] = mapped_column(
        String(50),
        unique=True,
        nullable=False
    )

    codigo_hex: Mapped[str | None] = mapped_column(
        String(7),
        nullable=True
    )

    activo: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )
