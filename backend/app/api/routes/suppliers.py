from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol
from app.schemas.supplier import (
    ProveedorCrear,
    ProveedorActualizar,
    ProveedorRespuesta
)
from app.services import supplier_service

router = APIRouter(
    tags=["Proveedores"]
)


@router.get(
    "",
    response_model=List[ProveedorRespuesta]
)
def listar_proveedores(
    solo_activos: bool = True,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Listar los proveedores (solo administradores)"""
    return supplier_service.listar_proveedores(db, solo_activos=solo_activos)


@router.get(
    "/{proveedor_id}",
    response_model=ProveedorRespuesta
)
def obtener_proveedor(
    proveedor_id: int,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Obtener un proveedor por su ID (solo administradores)"""
    return supplier_service.obtener_proveedor_por_id(db, proveedor_id)


@router.post(
    "",
    response_model=ProveedorRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_proveedor(
    datos: ProveedorCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Crear un nuevo proveedor (solo administradores)"""
    return supplier_service.crear_proveedor(db, datos)


@router.put(
    "/{proveedor_id}",
    response_model=ProveedorRespuesta
)
def actualizar_proveedor(
    proveedor_id: int,
    datos: ProveedorActualizar,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Actualizar un proveedor (solo administradores)"""
    return supplier_service.actualizar_proveedor(db, proveedor_id, datos)


@router.delete(
    "/{proveedor_id}",
    response_model=ProveedorRespuesta
)
def eliminar_proveedor(
    proveedor_id: int,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Desactivar un proveedor (solo administradores)"""
    return supplier_service.eliminar_proveedor(db, proveedor_id)
