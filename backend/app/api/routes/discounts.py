from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol
from app.schemas.discount import DescuentoCrear, DescuentoActualizar, DescuentoRespuesta
from app.services import discount_service

router = APIRouter(
    tags=["Descuentos"]
)


@router.get(
    "",
    response_model=List[DescuentoRespuesta]
)
def listar_descuentos(
    solo_activos: bool = True,
    db: Session = Depends(obtener_db)
):
    """Listar los descuentos/promociones"""
    return discount_service.listar_descuentos(db, solo_activos=solo_activos)


@router.post(
    "",
    response_model=DescuentoRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_descuento(
    datos: DescuentoCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Crear un nuevo descuento (solo administradores)"""
    return discount_service.crear_descuento(db, datos)


@router.put(
    "/{descuento_id}",
    response_model=DescuentoRespuesta
)
def actualizar_descuento(
    descuento_id: int,
    datos: DescuentoActualizar,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Actualizar un descuento (solo administradores)"""
    return discount_service.actualizar_descuento(db, descuento_id, datos)


@router.delete(
    "/{descuento_id}",
    response_model=DescuentoRespuesta
)
def eliminar_descuento(
    descuento_id: int,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Desactivar un descuento (solo administradores)"""
    return discount_service.eliminar_descuento(db, descuento_id)
