from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, obtener_usuario_actual
from app.models.user import Usuario
from app.schemas.notification import NotificacionRespuesta
from app.services import notification_service

router = APIRouter(
    tags=["Notificaciones"]
)


@router.get(
    "",
    response_model=List[NotificacionRespuesta]
)
def listar_mis_notificaciones(
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    return notification_service.listar_notificaciones(
        db,
        usuario_actual.id,
        solo_no_leidas=False
    )


@router.get(
    "/no-leidas",
    response_model=List[NotificacionRespuesta]
)
def listar_mis_notificaciones_no_leidas(
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    return notification_service.listar_notificaciones(
        db,
        usuario_actual.id,
        solo_no_leidas=True
    )


@router.put(
    "/{notificacion_id}/leer",
    response_model=NotificacionRespuesta
)
def marcar_notificacion_como_leida(
    notificacion_id: int,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    return notification_service.marcar_como_leida(
        db,
        usuario_actual.id,
        notificacion_id
    )
