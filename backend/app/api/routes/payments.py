"""
[Segundo Parcial] CU26 - Procesar pago (Stripe/QR)
[Segundo Parcial] RNF02 - Aislamiento de datos por empresa
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, obtener_usuario_actual
from app.models.order import Pedido
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


def _puede_operar_ajeno(usuario: Usuario) -> bool:
    """Admin/SuperAdmin pueden operar sobre pedidos de otros usuarios."""
    return usuario.rol in ("administrador", "superadmin")


def _obtener_pedido_validado(
    db: Session,
    pedido_id: int,
    usuario_actual: Usuario,
) -> Pedido:
    """
    [RNF02] Busca el pedido sin filtrar por tenant para que un SuperAdmin
    pueda operar sobre cualquier empresa, y valida el aislamiento de forma
    explícita para el resto de los roles.
    """
    pedido = db.query(Pedido).filter(Pedido.id == pedido_id).first()
    if not pedido:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pedido not found")
    es_superadmin = usuario_actual.rol == "superadmin"
    if not es_superadmin and pedido.empresa_id != usuario_actual.empresa_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Pedido no pertenece a su empresa",
        )
    return pedido


@router.post(
    "",
    response_model=PagoRespuesta,
    status_code=status.HTTP_201_CREATED
)
def registrar_pago(
    datos: PagoCrear,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db),
):
    """
    [Segundo Parcial] CU26 - Procesar pago (Stripe/QR)
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Validar que el pedido pertenezca a la empresa
    """
    _obtener_pedido_validado(db, datos.pedido_id, usuario_actual)
    return payment_service.registrar_pago(
        db,
        usuario_actual.id,
        datos,
        permitir_ajeno=_puede_operar_ajeno(usuario_actual),
    )


@router.get(
    "/pedido/{pedido_id}",
    response_model=List[PagoRespuesta]
)
def listar_pagos_pedido(
    pedido_id: int,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db),
):
    """
    [Segundo Parcial] CU26 - Procesar pago (Stripe/QR)
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    """
    _obtener_pedido_validado(db, pedido_id, usuario_actual)
    return payment_service.listar_pagos_pedido(
        db,
        usuario_actual.id,
        pedido_id,
        permitir_ajeno=_puede_operar_ajeno(usuario_actual),
    )

# ============================================================
# STRIPE - Pasarela de pago (RF19)
# ============================================================
from fastapi import Request, Header
from app.schemas.payment import (
    StripeIntentRequest,
    StripeIntentResponse,
    StripeConfirmRequest,
    StripeConfirmResponse,
    StripeConfigResponse,
)
from app.services import stripe_service


@router.get(
    "/stripe/config",
    response_model=StripeConfigResponse,
    tags=["Pagos - Stripe"]
)
def obtener_config_stripe():
    """Retorna la configuración pública de Stripe."""
    return stripe_service.obtener_config_publica()


@router.post(
    "/stripe/intent",
    response_model=StripeIntentResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["Pagos - Stripe"]
)
def crear_stripe_intent(
    datos: StripeIntentRequest,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db),
):
    """
    [Segundo Parcial] CU26 - Procesar pago (Stripe/QR)
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    CU19 - Administrar Tipo de Pago
    RF19 - Crear un PaymentIntent de Stripe para un pedido.
    """
    _obtener_pedido_validado(db, datos.pedido_id, usuario_actual)
    return stripe_service.crear_payment_intent(
        db,
        usuario_actual.id,
        datos.pedido_id,
        datos.moneda,
        permitir_ajeno=_puede_operar_ajeno(usuario_actual),
    )


@router.post(
    "/stripe/confirm",
    response_model=StripeConfirmResponse,
    tags=["Pagos - Stripe"]
)
def confirmar_stripe_pago(
    datos: StripeConfirmRequest,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    """
    CU19 - Administrar Tipo de Pago
    RF19 - Confirmar el estado de un PaymentIntent.
    """
    return stripe_service.confirmar_pago(
        db,
        usuario_actual.id,
        datos.payment_intent_id
    )


@router.post(
    "/stripe/webhook",
    tags=["Pagos - Stripe"]
)
async def stripe_webhook(
    request: Request,
    stripe_signature: str = Header(None, alias="stripe-signature")
):
    """
    RF19 - Recibir eventos de Stripe (payment_intent.succeeded, etc.).
    """
    payload = await request.body()
    return stripe_service.procesar_webhook(payload, stripe_signature)