from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol
from app.schemas.role import RolCrear, RolActualizar, RolRespuesta
from app.services import role_service

# ============================================================
# TRAZABILIDAD MENSTYLE
# CU: CU05 - Gestionar Roles
# RF: RF02 - Gestionar usuarios y roles
# ENDPOINT: GET/POST /api/roles, PUT/DELETE /api/roles/{id}
# CAPA: Backend FastAPI
# Catálogo dinámico de roles: reemplaza la lista fija
# ["cliente", "administrador"] usada antes en users.py/permissions.py.
# Consumido por: Angular (pages/admin-configuracion) y
# Flutter (services/roles_service.dart, screens/roles_page.dart)
# ============================================================
router = APIRouter(
    tags=["Roles"]
)


@router.get(
    "",
    response_model=List[RolRespuesta]
)
def listar_roles(
    solo_activos: bool = True,
    db: Session = Depends(obtener_db)
):
    """Listar los roles del sistema"""
    return role_service.listar_roles(db, solo_activos=solo_activos)


@router.post(
    "",
    response_model=RolRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_rol(
    datos: RolCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Crear un nuevo rol (solo administradores)"""
    return role_service.crear_rol(db, datos)


@router.put(
    "/{rol_id}",
    response_model=RolRespuesta
)
def actualizar_rol(
    rol_id: int,
    datos: RolActualizar,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Actualizar un rol (solo administradores)"""
    return role_service.actualizar_rol(db, rol_id, datos)


@router.delete(
    "/{rol_id}",
    response_model=RolRespuesta
)
def eliminar_rol(
    rol_id: int,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Desactivar un rol (solo administradores; los roles base no se pueden desactivar)"""
    return role_service.eliminar_rol(db, rol_id)
