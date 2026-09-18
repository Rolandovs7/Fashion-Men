# ============================================================
# TRAZABILIDAD MENSTYLE
# CU: CU19 - Administrar Tipo de Pago
# RF: RF19 - Integrar pasarela de pago para compras digitales
# ENDPOINT: POST /api/pagos/stripe/intent, /confirm
# CAPA: Backend FastAPI (Service)
# ============================================================
import os
from datetime import datetime, timezone
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

import stripe

from app.models.payment import Pago
from app.models.order import Pedido
from app.services.notification_service import crear_notificacion


# Configuración inicial (se re-configura en cada llamada por seguridad)
STRIPE_SECRET_KEY = os.getenv("STRIPE_SECRET_KEY", "")
STRIPE_PUBLISHABLE_KEY = os.getenv("STRIPE_PUBLISHABLE_KEY", "")


def _configurar_stripe():
    """Configura la API key de Stripe (se llama en cada request)."""
    secret = os.getenv("STRIPE_SECRET_KEY", "")
    if not secret:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Stripe no está configurado. Agrega STRIPE_SECRET_KEY al .env"
        )
    stripe.api_key = secret
    return secret


def obtener_config_publica() -> dict:
    """Retorna la configuración pública de Stripe."""
    publishable = os.getenv("STRIPE_PUBLISHABLE_KEY", "")
    secret = os.getenv("STRIPE_SECRET_KEY", "")
    return {
        "publishable_key": publishable,
        "modo": "test" if secret.startswith("sk_test_") else "live"
    }


def crear_payment_intent(
    db: Session,
    usuario_id: int,
    pedido_id: int,
    moneda: str = "usd"
) -> dict:
    """
    Crea un PaymentIntent en Stripe para un pedido.

    Flujo:
    1. Verificar que el pedido existe y pertenece al usuario
    2. Verificar que está en estado "pendiente"
    3. Crear PaymentIntent en Stripe
    4. Registrar intento de pago en BD (estado "pendiente")
    5. Retornar client_secret al frontend
    """
    _configurar_stripe()
    publishable = os.getenv("STRIPE_PUBLISHABLE_KEY", "")

    # 1. Verificar pedido
    pedido = db.query(Pedido).filter(
        Pedido.id == pedido_id,
        Pedido.usuario_id == usuario_id
    ).first()

    if not pedido:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pedido no encontrado"
        )

    if pedido.estado != "pendiente":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"El pedido está en estado '{pedido.estado}'. Solo se puede pagar si está pendiente."
        )

    # 2. Monto en centavos (Stripe usa centavos)
    monto_centavos = int(round(float(pedido.total) * 100))

    try:
        # 3. Crear PaymentIntent en Stripe
        intent = stripe.PaymentIntent.create(
            amount=monto_centavos,
            currency=moneda.lower(),
            metadata={
                "pedido_id": str(pedido.id),
                "usuario_id": str(usuario_id)
            },
            automatic_payment_methods={"enabled": True}
        )

        # 4. Registrar intento en BD
        pago = Pago(
            pedido_id=pedido.id,
            metodo="stripe",
            monto=float(pedido.total),
            estado="pendiente",
            referencia=intent.id,
            fecha_pago=None
        )
        db.add(pago)
        db.commit()
        db.refresh(pago)

        return {
            "client_secret": intent.client_secret,
            "payment_intent_id": intent.id,
            "monto": float(pedido.total),
            "moneda": moneda.upper(),
            "publishable_key": publishable
        }

    except stripe.error.StripeError as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error de Stripe: {str(e)}"
        )


def confirmar_pago(
    db: Session,
    usuario_id: int,
    payment_intent_id: str
) -> dict:
    """
    Consulta el estado del PaymentIntent en Stripe y actualiza el pago en BD.
    """
    _configurar_stripe()

    try:
        intent = stripe.PaymentIntent.retrieve(payment_intent_id)
    except stripe.error.StripeError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error consultando Stripe: {str(e)}"
        )

    # Buscar pago por referencia
    pago = db.query(Pago).filter(
        Pago.referencia == payment_intent_id
    ).first()

    if not pago:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pago no encontrado"
        )

    # Verificar que el pedido pertenece al usuario
    pedido = db.query(Pedido).filter(
        Pedido.id == pago.pedido_id,
        Pedido.usuario_id == usuario_id
    ).first()

    if not pedido:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permiso para confirmar este pago"
        )

    # Actualizar estado según Stripe
    if intent.status == "succeeded":
        pago.estado = "aprobado"
        pago.fecha_pago = datetime.now(timezone.utc)

        if pedido.estado == "pendiente":
            pedido.estado = "pagado"

            crear_notificacion(
                db,
                usuario_id=usuario_id,
                titulo="Pago Aprobado",
                mensaje=f"Se ha procesado exitosamente tu pago por ${pago.monto:.2f} para el pedido #{pedido.id}."
            )
    elif intent.status in ["requires_payment_method", "canceled"]:
        pago.estado = "rechazado"
    else:
        pago.estado = "pendiente"

    db.commit()
    db.refresh(pago)

    return {
        "payment_intent_id": payment_intent_id,
        "estado": intent.status,
        "monto": float(pago.monto),
        "moneda": intent.currency.upper()
    }