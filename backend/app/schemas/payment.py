from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class PagoCrear(BaseModel):
    pedido_id: int = Field(..., gt=0)
    metodo: str = Field(..., min_length=1, max_length=30)
    monto: float = Field(..., gt=0)
    referencia: Optional[str] = Field(None, max_length=150)


class PagoRespuesta(BaseModel):
    id: int
    pedido_id: int
    metodo: str
    monto: float
    estado: str
    referencia: Optional[str] = None
    fecha_pago: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

# ============================================================
# TRAZABILIDAD MENSTYLE
# CU: CU19 - Administrar Tipo de Pago
# RF: RF19 - Integrar pasarela de pago para compras digitales
# CAPA: Backend FastAPI (Schemas)
# ============================================================

class StripeIntentRequest(BaseModel):
    """Request para crear un PaymentIntent de Stripe."""
    pedido_id: int = Field(..., gt=0)
    moneda: str = Field("usd", min_length=3, max_length=3)


class StripeIntentResponse(BaseModel):
    """Response con el client_secret para el frontend."""
    client_secret: str
    payment_intent_id: str
    monto: float
    moneda: str
    publishable_key: str


class StripeConfirmRequest(BaseModel):
    """Request para confirmar un pago en Stripe."""
    payment_intent_id: str = Field(..., min_length=10)


class StripeConfirmResponse(BaseModel):
    """Response con el estado del pago."""
    payment_intent_id: str
    estado: str  # succeeded, requires_payment_method, processing, etc.
    monto: float
    moneda: str


class StripeConfigResponse(BaseModel):
    """Configuración pública de Stripe para el frontend."""
    publishable_key: str
    modo: str  # "test" o "live"

# ============================================================
# TRAZABILIDAD MENSTYLE
# CU: CU19 - Administrar Tipo de Pago
# RF: RF19 - Integrar pasarela de pago para compras digitales
# CAPA: Backend FastAPI (Schemas Stripe)
# ============================================================


class StripeIntentRequest(BaseModel):
    """Request para crear un PaymentIntent de Stripe."""
    pedido_id: int = Field(..., gt=0)
    moneda: str = Field("usd", min_length=3, max_length=3)


class StripeIntentResponse(BaseModel):
    """Response con el client_secret para el frontend."""
    client_secret: str
    payment_intent_id: str
    monto: float
    moneda: str
    publishable_key: str


class StripeConfirmRequest(BaseModel):
    """Request para confirmar un pago en Stripe."""
    payment_intent_id: str = Field(..., min_length=10)


class StripeConfirmResponse(BaseModel):
    """Response con el estado del pago."""
    payment_intent_id: str
    estado: str
    monto: float
    moneda: str


class StripeConfigResponse(BaseModel):
    """Configuración pública de Stripe."""
    publishable_key: str
    modo: str