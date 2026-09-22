from datetime import datetime, timezone

from sqlalchemy import String, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class PasswordResetToken(Base):
    """
    Token temporal para recuperación de contraseña.

    Flujo:
    1. Usuario pide reset → se crea un token con expira_en = now + 30 min.
    2. Se envía email con link /reset-password?token=<token>.
    3. Usuario abre link → backend valida token.
    4. Usuario cambia password → se marca usado = True.
    """
    __tablename__ = "password_reset_tokens"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    usuario_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id"),
        nullable=False,
        index=True
    )

    # UUID string único. Indexado para búsquedas rápidas.
    token: Mapped[str] = mapped_column(
        String(100),
        unique=True,
        nullable=False,
        index=True
    )

    expira_en: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False
    )

    usado: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False
    )

    fecha_creacion: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )