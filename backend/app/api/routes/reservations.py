from typing import List, Optional
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, obtener_usuario_actual, requerir_rol
from app.models.user import Usuario
from app.schemas.reservation import (
    ReservaCrear,
    ReservaCambiarEstado,
    ReservaRespuesta
)
from app.services import reservation_service

router = APIRouter(
    tags=["Reservas"]
)


@router.get(
    "",
    response_model=List[ReservaRespuesta]
)
def listar_mis_reservas(
    estado: Optional[str] = None,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    return reservation_service.listar_reservas_usuario(
        db,
        usuario_actual.id,
        estado=estado
    )


@router.get(
    "/admin/todas",
    response_model=List[ReservaRespuesta]
)
def listar_todas_las_reservas(
    estado: Optional[str] = None,
    sucursal_id: Optional[int] = None,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Listar todas las reservas de la plataforma (solo administradores)"""
    return reservation_service.listar_todas_las_reservas(
        db, estado=estado, sucursal_id=sucursal_id
    )


@router.get(
    "/{reserva_id}",
    response_model=ReservaRespuesta
)
def obtener_mi_reserva(
    reserva_id: int,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    return reservation_service.obtener_reserva_por_id(
        db,
        usuario_actual.id,
        reserva_id
    )


@router.post(
    "",
    response_model=ReservaRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_reserva(
    datos: ReservaCrear,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    return reservation_service.crear_reserva(
        db,
        usuario_actual.id,
        datos
    )


@router.put(
    "/{reserva_id}/cancelar",
    response_model=ReservaRespuesta
)
def cancelar_mi_reserva(
    reserva_id: int,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    return reservation_service.cancelar_reserva_cliente(
        db,
        usuario_actual.id,
        reserva_id
    )


@router.put(
    "/{reserva_id}/estado",
    response_model=ReservaRespuesta
)
def cambiar_estado_reserva_admin(
    reserva_id: int,
    datos: ReservaCambiarEstado,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    return reservation_service.cambiar_estado_reserva_admin(
        db,
        reserva_id,
        datos.nuevo_estado
    )
