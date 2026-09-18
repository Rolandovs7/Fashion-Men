# ============================================================
# TRAZABILIDAD MENSTYLE
# Endpoint temporal para ejecutar migraciones sin Shell
# RF: N/A - Solo para inicialización en producción
# ============================================================
import os
from fastapi import APIRouter, Header, HTTPException, status
from alembic.config import Config
from alembic import command

router = APIRouter(prefix="/admin", tags=["Admin"])

# Clave secreta simple (defínela en Render como variable de entorno)
ADMIN_KEY = os.getenv("ADMIN_MIGRATION_KEY", "menstyle-migrate-2026")


@router.post("/migrate")
def run_migrations(x_admin_key: str = Header(None)):
    """
    Ejecuta `alembic upgrade head` de forma remota.
    Solo se puede llamar con el header X-Admin-Key correcto.
    """
    if x_admin_key != ADMIN_KEY:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Clave de administración inválida"
        )
    
    try:
        # Ruta al alembic.ini dentro del contenedor
        alembic_cfg = Config("/app/alembic.ini")
        command.upgrade(alembic_cfg, "head")
        return {"status": "ok", "mensaje": "Migraciones aplicadas correctamente"}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error ejecutando migraciones: {str(e)}"
        )


@router.post("/seed")
def run_seed(x_admin_key: str = Header(None)):
    """Ejecuta el script seed_admin.py para crear el admin."""
    if x_admin_key != ADMIN_KEY:
        raise HTTPException(status_code=401, detail="Clave inválida")
    
    try:
        # Ejecutar el seed como módulo
        import subprocess
        result = subprocess.run(
            ["python", "seed_admin.py"],
            cwd="/app",
            capture_output=True,
            text=True
        )
        return {
            "status": "ok" if result.returncode == 0 else "error",
            "stdout": result.stdout,
            "stderr": result.stderr
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/seed-demo")
def run_seed_demo(x_admin_key: str = Header(None)):
    """
    Ejecuta el script seed_demo.py para poblar la BD con datos demo.

    Idempotente: si los datos ya existen, los omite.
    Cubre: CU07, CU08, CU10-CU17, CU26-CU31 (datos para demo).
    Requisito: RF04, RF05, RF06, RF07, RF21, RF22, RF23.
    """
    if x_admin_key != ADMIN_KEY:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Clave de administración inválida"
        )

    try:
        import subprocess
        result = subprocess.run(
            ["python", "seed_demo.py"],
            cwd="/app",
            capture_output=True,
            text=True,
            timeout=180  # 3 minutos máximo
        )
        return {
            "status": "ok" if result.returncode == 0 else "error",
            "stdout": result.stdout,
            "stderr": result.stderr,
            "returncode": result.returncode
        }
    except subprocess.TimeoutExpired:
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail="El seed tardó más de 3 minutos. Verifica los logs."
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error ejecutando seed-demo: {str(e)}"
        )
