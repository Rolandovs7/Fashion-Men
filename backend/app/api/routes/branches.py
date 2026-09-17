from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol
from app.schemas.branch import (
    SucursalCrear,
    SucursalActualizar,
    SucursalRespuesta
)
from app.services import branch_service

router = APIRouter(
    tags=["Sucursales"]
)


@router.get(
    "",
    response_model=List[SucursalRespuesta]
)
def listar_sucursales(
    solo_activos: bool = True,
    db: Session = Depends(obtener_db)
):
    """Listar las sucursales de la cadena"""
    return branch_service.listar_sucursales(db, solo_activos=solo_activos)


@router.get(
    "/{sucursal_id}",
    response_model=SucursalRespuesta
)
def obtener_sucursal(
    sucursal_id: int,
    db: Session = Depends(obtener_db)
):
    """Obtener una sucursal por su ID"""
    return branch_service.obtener_sucursal_por_id(db, sucursal_id)


@router.post(
    "",
    response_model=SucursalRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_sucursal(
    datos: SucursalCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Crear una nueva sucursal (solo administradores)"""
    return branch_service.crear_sucursal(db, datos)


@router.put(
    "/{sucursal_id}",
    response_model=SucursalRespuesta
)
def actualizar_sucursal(
    sucursal_id: int,
    datos: SucursalActualizar,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Actualizar una sucursal (solo administradores)"""
    return branch_service.actualizar_sucursal(db, sucursal_id, datos)


@router.delete(
    "/{sucursal_id}",
    response_model=SucursalRespuesta
)
def eliminar_sucursal(
    sucursal_id: int,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Desactivar una sucursal (solo administradores)"""
    return branch_service.eliminar_sucursal(db, sucursal_id)
