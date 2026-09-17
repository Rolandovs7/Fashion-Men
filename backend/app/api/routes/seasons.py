from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol
from app.schemas.season import (
    TemporadaCrear,
    TemporadaActualizar,
    TemporadaRespuesta
)
from app.services import season_service

router = APIRouter(
    tags=["Temporadas"]
)


@router.get(
    "",
    response_model=List[TemporadaRespuesta]
)
def listar_temporadas(
    solo_activos: bool = True,
    db: Session = Depends(obtener_db)
):
    """Listar las temporadas comerciales"""
    return season_service.listar_temporadas(db, solo_activos=solo_activos)


@router.post(
    "",
    response_model=TemporadaRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_temporada(
    datos: TemporadaCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Crear una nueva temporada (solo administradores)"""
    return season_service.crear_temporada(db, datos)


@router.put(
    "/{temporada_id}",
    response_model=TemporadaRespuesta
)
def actualizar_temporada(
    temporada_id: int,
    datos: TemporadaActualizar,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Actualizar una temporada (solo administradores)"""
    return season_service.actualizar_temporada(db, temporada_id, datos)


@router.delete(
    "/{temporada_id}",
    response_model=TemporadaRespuesta
)
def eliminar_temporada(
    temporada_id: int,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Desactivar una temporada (solo administradores)"""
    return season_service.eliminar_temporada(db, temporada_id)
