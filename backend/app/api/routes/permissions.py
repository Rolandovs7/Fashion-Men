from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol
from app.models.user import Usuario
from app.models.permission import Permiso, RolPermiso
from app.schemas.permissions import PermisoRespuesta, AsignarPermiso
from app.services import role_service

router = APIRouter(prefix="/permisos", tags=["Permisos"])

# ============================================================
# TRAZABILIDAD MENSTYLE
# CU: CU06 - Asignar Permisos (Riesgo: CRÍTICO)
# RF: RF02 - Gestionar usuarios y roles (relacionado; no existe un
#     RF explícito de "permisos" en el documento oficial de 25 RF)
# ENDPOINT: GET /api/permisos, GET /api/permisos/rol/{rol},
#           POST /api/permisos/asignar, DELETE /api/permisos/quitar/{rol}/{permiso_id}
# CAPA: Backend FastAPI
# Todas las rutas exigen requerir_rol("administrador") — es el punto
# de control de acceso más sensible del sistema (de aquí depende que
# un rol tenga o no permisos reales sobre el resto del panel admin).
# ============================================================


@router.get("", response_model=list[PermisoRespuesta])
def listar_permisos(
    db: Session = Depends(obtener_db),
    usuario_actual: Usuario = Depends(requerir_rol("administrador"))
):
    return (
        db.query(Permiso)
        .filter(Permiso.activo == True)
        .order_by(Permiso.id)
        .all()
    )


@router.get("/rol/{rol}")
def permisos_por_rol(
    rol: str,
    db: Session = Depends(obtener_db),
    usuario_actual: Usuario = Depends(requerir_rol("administrador"))
):
    return (
        db.query(Permiso)
        .join(RolPermiso, RolPermiso.permiso_id == Permiso.id)
        .filter(RolPermiso.rol == rol)
        .order_by(Permiso.id)
        .all()
    )


@router.post("/asignar")
def asignar_permiso(
    datos: AsignarPermiso,
    db: Session = Depends(obtener_db),
    usuario_actual: Usuario = Depends(requerir_rol("administrador"))
):
    if datos.rol not in role_service.nombres_roles_activos(db):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rol inválido"
        )

    permiso = db.query(Permiso).filter(
        Permiso.id == datos.permiso_id
    ).first()

    if not permiso:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Permiso no encontrado"
        )

    existe = db.query(RolPermiso).filter(
        RolPermiso.rol == datos.rol,
        RolPermiso.permiso_id == datos.permiso_id
    ).first()

    if existe:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El permiso ya está asignado"
        )

    db.add(
        RolPermiso(
            rol=datos.rol,
            permiso_id=datos.permiso_id
        )
    )

    db.commit()

    return {"mensaje": "Permiso asignado correctamente"}


@router.delete("/quitar/{rol}/{permiso_id}")
def quitar_permiso(
    rol: str,
    permiso_id: int,
    db: Session = Depends(obtener_db),
    usuario_actual: Usuario = Depends(requerir_rol("administrador"))
):
    asignacion = db.query(RolPermiso).filter(
        RolPermiso.rol == rol,
        RolPermiso.permiso_id == permiso_id
    ).first()

    if not asignacion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El permiso no está asignado"
        )

    db.delete(asignacion)
    db.commit()

    return {"mensaje": "Permiso quitado correctamente"}
