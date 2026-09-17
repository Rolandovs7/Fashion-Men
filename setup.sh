#!/bin/bash

# ============================================================
# MenStyle - Script de configuración inicial
# Backend: FastAPI + SQLAlchemy + Alembic + PostgreSQL
# Frontend: Angular
# Mobile: Flutter
# ============================================================

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"

echo ""
echo "=========================================="
echo "        MENSTYLE - SETUP INICIAL"
echo "=========================================="
echo ""

# ------------------------------------------------------------
# 1. Verificar herramientas básicas
# ------------------------------------------------------------

echo "[1/8] Verificando herramientas..."

command -v python3 >/dev/null 2>&1 || {
    echo "ERROR: Python 3 no está instalado."
    exit 1
}

command -v git >/dev/null 2>&1 || {
    echo "ERROR: Git no está instalado."
    exit 1
}

echo "✓ Python: $(python3 --version)"
echo "✓ Git: $(git --version)"

# ------------------------------------------------------------
# 2. Crear estructura principal
# ------------------------------------------------------------

echo ""
echo "[2/8] Creando estructura del proyecto..."

mkdir -p "$BACKEND_DIR/app/api/routes"
mkdir -p "$BACKEND_DIR/app/core"
mkdir -p "$BACKEND_DIR/app/models"
mkdir -p "$BACKEND_DIR/app/schemas"
mkdir -p "$BACKEND_DIR/app/services"
mkdir -p "$BACKEND_DIR/tests"

mkdir -p "$PROJECT_ROOT/frontend"
mkdir -p "$PROJECT_ROOT/mobile"
mkdir -p "$PROJECT_ROOT/docs/diagramas"
mkdir -p "$PROJECT_ROOT/docs/documentacion"

echo "✓ Estructura creada."

# ------------------------------------------------------------
# 3. Crear archivos __init__.py
# ------------------------------------------------------------

echo ""
echo "[3/8] Preparando paquetes Python..."

touch "$BACKEND_DIR/app/__init__.py"
touch "$BACKEND_DIR/app/api/__init__.py"
touch "$BACKEND_DIR/app/api/routes/__init__.py"
touch "$BACKEND_DIR/app/core/__init__.py"
touch "$BACKEND_DIR/app/models/__init__.py"
touch "$BACKEND_DIR/app/schemas/__init__.py"
touch "$BACKEND_DIR/app/services/__init__.py"
touch "$BACKEND_DIR/tests/__init__.py"

echo "✓ Paquetes Python preparados."

# ------------------------------------------------------------
# 4. Crear entorno virtual
# ------------------------------------------------------------

echo ""
echo "[4/8] Preparando entorno virtual..."

if [ ! -d "$BACKEND_DIR/venv" ]; then
    python3 -m venv "$BACKEND_DIR/venv"
    echo "✓ Entorno virtual creado."
else
    echo "✓ Entorno virtual ya existe."
fi

source "$BACKEND_DIR/venv/bin/activate"

# ------------------------------------------------------------
# 5. Instalar dependencias backend
# ------------------------------------------------------------

echo ""
echo "[5/8] Instalando dependencias del backend..."

python -m pip install --upgrade pip

pip install \
    "fastapi==0.141.1" \
    "uvicorn[standard]" \
    "sqlalchemy==2.0.52" \
    "psycopg2-binary==2.9.12" \
    "python-dotenv" \
    "python-multipart" \
    "alembic==1.19.1"

echo "✓ Dependencias instaladas."

# ------------------------------------------------------------
# 6. Crear requirements.txt
# ------------------------------------------------------------

echo ""
echo "[6/8] Actualizando requirements.txt..."

pip freeze > "$BACKEND_DIR/requirements.txt"

echo "✓ requirements.txt actualizado."

# ------------------------------------------------------------
# 7. Verificaciones
# ------------------------------------------------------------

echo ""
echo "[7/8] Verificando instalación..."

python -c "import fastapi; print('✓ FastAPI:', fastapi.__version__)"
python -c "import sqlalchemy; print('✓ SQLAlchemy:', sqlalchemy.__version__)"
python -c "import psycopg2; print('✓ psycopg2:', psycopg2.__version__.split()[0])"
python -c "import alembic; print('✓ Alembic:', alembic.__version__)"

# ------------------------------------------------------------
# 8. Resumen
# ------------------------------------------------------------

echo ""
echo "[8/8] Configuración finalizada."

echo ""
echo "=========================================="
echo "        MENSTYLE - SETUP COMPLETADO"
echo "=========================================="
echo ""
echo "Proyecto:"
echo "  $PROJECT_ROOT"
echo ""
echo "Backend:"
echo "  $BACKEND_DIR"
echo ""
echo "Entorno virtual:"
echo "  $BACKEND_DIR/venv"
echo ""
echo "Para activar el entorno:"
echo "  cd $BACKEND_DIR"
echo "  source venv/bin/activate"
echo ""
echo "Para ejecutar FastAPI:"
echo "  uvicorn app.main:app --reload"
echo ""
echo "=========================================="
