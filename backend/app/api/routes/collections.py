from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol
from app.schemas.collection import (
    ColeccionCrear,
    ColeccionActualizar,
    ColeccionRespuesta
)
from app.services import collection_service

router = APIRouter(
    tags=["Colecciones"]
)


@router.get(
    "",
    response_model=List[ColeccionRespuesta]
)
def listar_colecciones(
    solo_activos: bool = True,
    db: Session = Depends(obtener_db)
):
    """Listar las colecciones"""
    return collection_service.listar_colecciones(db, solo_activos=solo_activos)


@router.post(
    "",
    response_model=ColeccionRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_coleccion(
    datos: ColeccionCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Crear una nueva colección (solo administradores)"""
    return collection_service.crear_coleccion(db, datos)


@router.put(
    "/{coleccion_id}",
    response_model=ColeccionRespuesta
)
def actualizar_coleccion(
    coleccion_id: int,
    datos: ColeccionActualizar,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Actualizar una colección (solo administradores)"""
    return collection_service.actualizar_coleccion(db, coleccion_id, datos)


@router.delete(
    "/{coleccion_id}",
    response_model=ColeccionRespuesta
)
def eliminar_coleccion(
    coleccion_id: int,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Desactivar una colección (solo administradores)"""
    return collection_service.eliminar_coleccion(db, coleccion_id)
