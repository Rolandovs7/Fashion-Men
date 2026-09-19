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

# Clave secreta OBLIGATORIA (defínela en Render como variable de entorno).
# Si no existe, el módulo falla al importar (protección contra mala configuración).
ADMIN_KEY = os.getenv("ADMIN_MIGRATION_KEY")
if not ADMIN_KEY:
    raise RuntimeError(
        "ADMIN_MIGRATION_KEY no está definida. "
        "Configúrala en Render → Environment antes de desplegar."
    )

# Flag para habilitar endpoints destructivos (/seed, /seed-demo, /fix-imagenes).
# Por defecto FALSE en producción. Ponlo en "true" temporalmente si necesitas
# re-ejecutar un seed o fix. Vuelve a "false" después.
ALLOW_DESTRUCTIVE_ENDPOINTS = os.getenv("ALLOW_DESTRUCTIVE_ENDPOINTS", "false").lower() == "true"


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
    """Ejecuta el script seed_admin.py para crear el admin.

    BLOQUEADO en producción salvo que ALLOW_DESTRUCTIVE_ENDPOINTS=true.
    """
    if not ALLOW_DESTRUCTIVE_ENDPOINTS:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Endpoint deshabilitado en producción."
        )
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

    BLOQUEADO en producción salvo que ALLOW_DESTRUCTIVE_ENDPOINTS=true.
    """
    if not ALLOW_DESTRUCTIVE_ENDPOINTS:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Endpoint deshabilitado en producción."
        )
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


@router.post("/fix-imagenes")
def fix_imagenes(x_admin_key: str = Header(None)):
    """
    Actualiza imagen_url de los 15 productos demo con rutas locales
    bajo /imagenes/<categoria>/<archivo>.jpg

    Idempotente: se puede ejecutar múltiples veces sin efectos adversos.

    BLOQUEADO en producción salvo que ALLOW_DESTRUCTIVE_ENDPOINTS=true.
    """
    if not ALLOW_DESTRUCTIVE_ENDPOINTS:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Endpoint deshabilitado en producción."
        )
    if x_admin_key != ADMIN_KEY:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Clave de administración inválida"
        )

    # Mapeo: nombre del producto -> ruta de imagen
    MAPA = {
        "Camisa Formal Blanca":          "/imagenes/camisas/camisa-formal-blanca.jpg",
        "Camisa Casual Azul":            "/imagenes/camisas/camisa-casual-azul.jpg",
        "Pantalón de Vestir Negro":      "/imagenes/pantalones/pantalon-vestir-negro.jpg",
        "Jean Clásico Azul":             "/imagenes/pantalones/jean-clasico-azul.jpg",
        "Zapato Formal Negro":           "/imagenes/zapatos/zapato-formal-negro.jpg",
        "Zapatilla Deportiva Blanca":    "/imagenes/zapatos/zapatilla-deportiva-blanca.jpg",
        "Zapatilla Urbana Negra":        "/imagenes/zapatos/zapatilla-urbana-negra.jpg",
        "Chaqueta de Cuero":             "/imagenes/chaquetas/chaqueta-cuero.jpg",
        "Chaqueta Deportiva":            "/imagenes/chaquetas/chaqueta-deportiva.jpg",
        "Polera Básica Negra":           "/imagenes/poleras/polera-basica-negra.jpg",
        "Polera Estampada":              "/imagenes/poleras/polera-estampada.jpg",
        "Traje Completo Gris":           "/imagenes/trajes/traje-completo-gris.jpg",
        "Short Deportivo":               "/imagenes/ropa-deportiva/short-deportivo.jpg",
        "Cinturón de Cuero":             "/imagenes/accesorios/cinturon-cuero.jpg",
        "Bufanda de Lana":               "/imagenes/accesorios/bufanda-lana.jpg",
    }

    try:
        from app.core.database import SessionLocal
        from app.models.product import Producto

        db = SessionLocal()
        try:
            actualizados = 0
            no_encontrados = []

            for nombre, ruta in MAPA.items():
                producto = db.query(Producto).filter(Producto.nombre == nombre).first()
                if producto:
                    producto.imagen_url = ruta
                    actualizados += 1
                else:
                    no_encontrados.append(nombre)

            db.commit()

            return {
                "status": "ok",
                "actualizados": actualizados,
                "total_mapa": len(MAPA),
                "no_encontrados": no_encontrados,
                "mensaje": f"{actualizados}/{len(MAPA)} productos actualizados con imagen local"
            }
        finally:
            db.close()

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error actualizando imágenes: {str(e)}"
        )
