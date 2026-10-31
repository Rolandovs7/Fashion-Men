"""
[Segundo Parcial] CU01 - Registrar empresa y contratar plan
[Segundo Parcial] CU02 - Suscripción
[Segundo Parcial] RF01 - Gestión Multitenant y Empresas
Consumido por: Frontend (Admin)
"""
from datetime import datetime, timezone

from sqlalchemy import String, Boolean, DateTime, ForeignKey, Integer
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Empresa(Base):
    """
    [Segundo Parcial] CU01 - Registrar empresa y contratar plan
    [Segundo Parcial] RF01 - Gestión Multitenant y Empresas
    """
    __tablename__ = "empresas"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    nombre: Mapped[str] = mapped_column(
        String(150),
        nullable=False,
        unique=True
    )

    fecha_registro: Mapped[datetime] = mapped_column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )

    activo: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )


class Plan(Base):
    """
    [Segundo Parcial] CU01 - Registrar empresa y contratar plan
    [Segundo Parcial] RF01 - Gestión Multitenant y Empresas
    """
    __tablename__ = "planes"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    nombre: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        unique=True
    )

    max_sucursales: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=2
    )

    permite_ia: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False
    )

    permite_offline: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False
    )


class Suscripcion(Base):
    """
    [Segundo Parcial] CU02 - Suscripción
    [Segundo Parcial] RF01 - Gestión Multitenant y Empresas
    """
    __tablename__ = "suscripciones"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    empresa_id: Mapped[int] = mapped_column(
        ForeignKey("empresas.id"),
        nullable=False,
        index=True
    )

    plan_id: Mapped[int] = mapped_column(
        ForeignKey("planes.id"),
        nullable=False,
        index=True
    )

    fecha_inicio: Mapped[datetime] = mapped_column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )

    fecha_fin: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True
    )

    estado: Mapped[str] = mapped_column(
        String(20),
        default="activo",
        nullable=False
    )
