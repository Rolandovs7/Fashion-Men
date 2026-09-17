from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, obtener_usuario_actual, requerir_rol
from app.models.user import Usuario
from app.schemas.return_schema import (
    DevolucionSolicitar,
    DevolucionCambiarEstadoAdmin,
    DevolucionRespuesta
)
from app.services import return_service

router = APIRouter(
    tags=["Devoluciones"]
)


@router.get(
    "",
    response_model=List[DevolucionRespuesta]
)
def listar_mis_devoluciones(
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    return return_service.listar_devoluciones_usuario(
        db,
        usuario_actual.id
    )


@router.get(
    "/{devolucion_id}",
    response_model=DevolucionRespuesta
)
def obtener_mi_devolucion(
    devolucion_id: int,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    return return_service.obtener_devolucion_por_id(
        db,
        usuario_actual.id,
        devolucion_id
    )


@router.post(
    "",
    response_model=DevolucionRespuesta,
    status_code=status.HTTP_201_CREATED
)
def solicitar_devolucion(
    datos: DevolucionSolicitar,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    return return_service.solicitar_devolucion(
        db,
        usuario_actual.id,
        datos
    )


@router.put(
    "/{devolucion_id}/estado",
    response_model=DevolucionRespuesta
)
def cambiar_estado_devolucion_admin(
    devolucion_id: int,
    datos: DevolucionCambiarEstadoAdmin,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    return return_service.cambiar_estado_devolucion_admin(
        db,
        devolucion_id,
        datos
    )
