from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol
from app.schemas.brand import MarcaCrear, MarcaActualizar, MarcaRespuesta
from app.services import brand_service

router = APIRouter(
    tags=["Marcas"]
)


@router.get(
    "",
    response_model=List[MarcaRespuesta]
)
def listar_marcas(
    solo_activos: bool = True,
    db: Session = Depends(obtener_db)
):
    """Listar las marcas"""
    return brand_service.listar_marcas(db, solo_activos=solo_activos)


@router.post(
    "",
    response_model=MarcaRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_marca(
    datos: MarcaCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Crear una nueva marca (solo administradores)"""
    return brand_service.crear_marca(db, datos)


@router.put(
    "/{marca_id}",
    response_model=MarcaRespuesta
)
def actualizar_marca(
    marca_id: int,
    datos: MarcaActualizar,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Actualizar una marca (solo administradores)"""
    return brand_service.actualizar_marca(db, marca_id, datos)


@router.delete(
    "/{marca_id}",
    response_model=MarcaRespuesta
)
def eliminar_marca(
    marca_id: int,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Desactivar una marca (solo administradores)"""
    return brand_service.eliminar_marca(db, marca_id)
