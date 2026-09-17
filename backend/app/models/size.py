from sqlalchemy import String, Boolean
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Talla(Base):
    __tablename__ = "tallas"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    nombre: Mapped[str] = mapped_column(
        String(20),
        unique=True,
        nullable=False
    )

    activo: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )
