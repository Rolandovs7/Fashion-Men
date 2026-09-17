from sqlalchemy import String, Boolean, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Permiso(Base):
    __tablename__ = "permisos"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    nombre: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    descripcion: Mapped[str] = mapped_column(String(255), nullable=False)
    activo: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)


class RolPermiso(Base):
    __tablename__ = "rol_permisos"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)

    rol: Mapped[str] = mapped_column(
        String(30),
        nullable=False,
        index=True
    )

    permiso_id: Mapped[int] = mapped_column(
        ForeignKey("permisos.id", ondelete="CASCADE"),
        nullable=False
    )
