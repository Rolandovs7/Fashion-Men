from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, obtener_usuario_actual
from app.models.user import Usuario
from app.schemas.payment import PagoCrear, PagoRespuesta
from app.services import payment_service

# ============================================================
# CU18 - Administrar Tipo de Pago / pago en punto de caja
# CU20 - Nota de Venta (el detalle de pago es parte del comprobante)
# RF18 - Permitir pagos en punto de caja
# RF19 - Integrar una pasarela de pago para compras digitales (sandbox propio)
# Consumido por: Angular (ReciboComponent, pedidos, punto-venta)
# Flutter: aún no consumido (CU20 pendiente de implementar en móvil)
# ============================================================
router = APIRouter(
    tags=["Pagos"]
)


@router.post(
    "",
    response_model=PagoRespuesta,
    status_code=status.HTTP_201_CREATED
)
def registrar_pago(
    datos: PagoCrear,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    return payment_service.registrar_pago(
        db,
        usuario_actual.id,
        datos
    )


@router.get(
    "/pedido/{pedido_id}",
    response_model=List[PagoRespuesta]
)
def listar_pagos_pedido(
    pedido_id: int,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    return payment_service.listar_pagos_pedido(
        db,
        usuario_actual.id,
        pedido_id
    )
