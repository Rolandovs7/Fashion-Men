from datetime import datetime, timezone

from sqlalchemy import String, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Notificacion(Base):
    __tablename__ = "notificaciones"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    usuario_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id"),
        nullable=False
    )

    titulo: Mapped[str] = mapped_column(
        String(150),
        nullable=False
    )

    mensaje: Mapped[str] = mapped_column(
        String(500),
        nullable=False
    )

    leida: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False
    )

    fecha_creacion: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        nullable=False
    )
