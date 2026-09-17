#!/bin/bash

set -e

echo "=================================="
echo "   MENSTYLE - CREAR MODELOS"
echo "=================================="

mkdir -p app/models

# ==========================================
# TEMPORADAS
# ==========================================

cat > app/models/season.py <<'PYTHON'
from sqlalchemy import String, Boolean
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Temporada(Base):
    __tablename__ = "temporadas"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    nombre: Mapped[str] = mapped_column(
        String(100),
        unique=True,
        nullable=False
    )

    descripcion: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True
    )

    activo: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )
PYTHON

echo "✅ Modelo Temporada preparado"


# ==========================================
# COLECCIONES
# ==========================================

cat > app/models/collection.py <<'PYTHON'
from sqlalchemy import String, Boolean
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Coleccion(Base):
    __tablename__ = "colecciones"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    nombre: Mapped[str] = mapped_column(
        String(100),
        unique=True,
        nullable=False
    )

    descripcion: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True
    )

    activo: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )
PYTHON

echo "✅ Modelo Coleccion preparado"


# ==========================================
# PROVEEDORES
# ==========================================

cat > app/models/supplier.py <<'PYTHON'
from sqlalchemy import String, Boolean
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Proveedor(Base):
    __tablename__ = "proveedores"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    nombre: Mapped[str] = mapped_column(
        String(150),
        nullable=False
    )

    contacto: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True
    )

    telefono: Mapped[str | None] = mapped_column(
        String(30),
        nullable=True
    )

    email: Mapped[str | None] = mapped_column(
        String(150),
        nullable=True
    )

    direccion: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True
    )

    activo: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )
PYTHON

echo "✅ Modelo Proveedor preparado"


# ==========================================
# VERIFICAR ARCHIVOS FUTUROS
# ==========================================

echo ""
echo "=================================="
echo "Archivos de modelos:"
echo "=================================="

ls -1 app/models/

echo ""
echo "=================================="
echo "Modelos preparados correctamente."
echo "=================================="
