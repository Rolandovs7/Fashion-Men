from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol
from app.schemas.garment_type import TipoPrendaCrear, TipoPrendaActualizar, TipoPrendaRespuesta
from app.services import garment_type_service

router = APIRouter(
    tags=["Tipos de Prenda"]
)


@router.get(
    "",
    response_model=List[TipoPrendaRespuesta]
)
def listar_tipos_prenda(
    solo_activos: bool = True,
    db: Session = Depends(obtener_db)
):
    """Listar los tipos de prenda"""
    return garment_type_service.listar_tipos_prenda(db, solo_activos=solo_activos)


@router.post(
    "",
    response_model=TipoPrendaRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_tipo_prenda(
    datos: TipoPrendaCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Crear un nuevo tipo de prenda (solo administradores)"""
    return garment_type_service.crear_tipo_prenda(db, datos)


@router.put(
    "/{tipo_prenda_id}",
    response_model=TipoPrendaRespuesta
)
def actualizar_tipo_prenda(
    tipo_prenda_id: int,
    datos: TipoPrendaActualizar,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Actualizar un tipo de prenda (solo administradores)"""
    return garment_type_service.actualizar_tipo_prenda(db, tipo_prenda_id, datos)


@router.delete(
    "/{tipo_prenda_id}",
    response_model=TipoPrendaRespuesta
)
def eliminar_tipo_prenda(
    tipo_prenda_id: int,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Desactivar un tipo de prenda (solo administradores)"""
    return garment_type_service.eliminar_tipo_prenda(db, tipo_prenda_id)
