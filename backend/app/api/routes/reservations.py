"""
[Segundo Parcial] CU11 - Gestionar reservas
[Segundo Parcial] RNF02 - Aislamiento de datos por empresa
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, obtener_usuario_actual, requerir_rol, get_current_empresa_id
from app.models.branch import Sucursal
from app.models.product import Producto
from app.models.product_variant import ProductoVariante
from app.models.reservation import Reserva
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
    """
    [Segundo Parcial] CU11 - Gestionar reservas
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    """
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
    _usuario_admin=Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU11 - Gestionar reservas
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Listar todas las reservas de la empresa (solo administradores)
    """
    query = db.query(Reserva).filter(Reserva.empresa_id == empresa_id)
    if estado:
        query = query.filter(Reserva.estado == estado)
    if sucursal_id is not None:
        sucursal = db.query(Sucursal).filter(Sucursal.id == sucursal_id).first()
        if not sucursal or sucursal.empresa_id != empresa_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sucursal no pertenece a su empresa")
        query = query.filter(Reserva.sucursal_id == sucursal_id)
    return query.all()


@router.get(
    "/{reserva_id}",
    response_model=ReservaRespuesta
)
def obtener_mi_reserva(
    reserva_id: int,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    """
    [Segundo Parcial] CU11 - Gestionar reservas
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    """
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
    db: Session = Depends(obtener_db),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU11 - Gestionar reservas
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Crear reserva validando sucursal y variantes pertenecen a la empresa
    """
    sucursal = db.query(Sucursal).filter(Sucursal.id == datos.sucursal_id).first()
    if not sucursal or sucursal.empresa_id != empresa_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sucursal no pertenece a su empresa")
    for item in datos.items:
        variante = db.query(ProductoVariante).filter(ProductoVariante.id == item.variante_id).first()
        if not variante:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Variante no encontrada")
        producto = db.query(Producto).filter(Producto.id == variante.producto_id).first()
        if not producto or producto.empresa_id != empresa_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Variante no pertenece al catálogo de su empresa")
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
