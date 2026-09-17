from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol
from app.schemas.payment_type import TipoPagoCrear, TipoPagoActualizar, TipoPagoRespuesta
from app.services import payment_type_service

# ============================================================
# CU19 - Administrar Tipo de Pago
# RF18 - Permitir pagos en punto de caja
# RF19 - Integrar una pasarela de pago para compras digitales (sandbox propio)
# Catálogo dinámico de métodos de pago habilitados; reemplaza la lista fija
# ["efectivo","tarjeta","qr"] antes hardcodeada en payment_service.py/order_service.py.
# Consumido por: Angular (admin-configuracion, pedidos, punto-venta)
# y Flutter (tipos_pago_page, mis_pedidos_page, punto_venta_page)
# ============================================================
router = APIRouter(
    tags=["Tipos de Pago"]
)


@router.get(
    "",
    response_model=List[TipoPagoRespuesta]
)
def listar_tipos_pago(
    solo_activos: bool = True,
    db: Session = Depends(obtener_db)
):
    """Listar los tipos de pago habilitados"""
    return payment_type_service.listar_tipos_pago(db, solo_activos=solo_activos)


@router.post(
    "",
    response_model=TipoPagoRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_tipo_pago(
    datos: TipoPagoCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Crear un nuevo tipo de pago (solo administradores)"""
    return payment_type_service.crear_tipo_pago(db, datos)


@router.put(
    "/{tipo_pago_id}",
    response_model=TipoPagoRespuesta
)
def actualizar_tipo_pago(
    tipo_pago_id: int,
    datos: TipoPagoActualizar,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Actualizar un tipo de pago (solo administradores)"""
    return payment_type_service.actualizar_tipo_pago(db, tipo_pago_id, datos)


@router.delete(
    "/{tipo_pago_id}",
    response_model=TipoPagoRespuesta
)
def eliminar_tipo_pago(
    tipo_pago_id: int,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Desactivar un tipo de pago (solo administradores)"""
    return payment_type_service.eliminar_tipo_pago(db, tipo_pago_id)
