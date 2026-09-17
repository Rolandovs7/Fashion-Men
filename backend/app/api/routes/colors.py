from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol
from app.schemas.color import ColorCrear, ColorActualizar, ColorRespuesta
from app.services import color_service

router = APIRouter(
    tags=["Colores"]
)


@router.get(
    "",
    response_model=List[ColorRespuesta]
)
def listar_colores(
    solo_activos: bool = True,
    db: Session = Depends(obtener_db)
):
    """Listar los colores disponibles"""
    return color_service.listar_colores(db, solo_activos=solo_activos)


@router.post(
    "",
    response_model=ColorRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_color(
    datos: ColorCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Crear un nuevo color (solo administradores)"""
    return color_service.crear_color(db, datos)


@router.put(
    "/{color_id}",
    response_model=ColorRespuesta
)
def actualizar_color(
    color_id: int,
    datos: ColorActualizar,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Actualizar un color (solo administradores)"""
    return color_service.actualizar_color(db, color_id, datos)


@router.delete(
    "/{color_id}",
    response_model=ColorRespuesta
)
def eliminar_color(
    color_id: int,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Desactivar un color (solo administradores)"""
    return color_service.eliminar_color(db, color_id)
