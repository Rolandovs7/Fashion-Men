from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol
from app.schemas.size import TallaCrear, TallaActualizar, TallaRespuesta
from app.services import size_service

router = APIRouter(
    tags=["Tallas"]
)


@router.get(
    "",
    response_model=List[TallaRespuesta]
)
def listar_tallas(
    solo_activos: bool = True,
    db: Session = Depends(obtener_db)
):
    """Listar las tallas disponibles"""
    return size_service.listar_tallas(db, solo_activos=solo_activos)


@router.post(
    "",
    response_model=TallaRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_talla(
    datos: TallaCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Crear una nueva talla (solo administradores)"""
    return size_service.crear_talla(db, datos)


@router.put(
    "/{talla_id}",
    response_model=TallaRespuesta
)
def actualizar_talla(
    talla_id: int,
    datos: TallaActualizar,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Actualizar una talla (solo administradores)"""
    return size_service.actualizar_talla(db, talla_id, datos)


@router.delete(
    "/{talla_id}",
    response_model=TallaRespuesta
)
def eliminar_talla(
    talla_id: int,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Desactivar una talla (solo administradores)"""
    return size_service.eliminar_talla(db, talla_id)
