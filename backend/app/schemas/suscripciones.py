from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class PlanRead(BaseModel):
    id: int
    nombre: str
    max_sucursales: int
    permite_ia: bool
    permite_offline: bool
    precio_mensual: Decimal
    descripcion: str | None = None

    model_config = ConfigDict(from_attributes=True)


class SuscripcionActualRead(BaseModel):
    id: int
    empresa_id: int
    plan: PlanRead
    fecha_inicio: datetime
    fecha_fin: datetime | None = None
    estado: str

    model_config = ConfigDict(from_attributes=True)


class CambiarPlanRequest(BaseModel):
    plan_id: int = Field(..., gt=0)


class CheckoutPlanResponse(BaseModel):
    """[Segundo Parcial] CU02 - Respuesta de inicio de checkout (simulado)."""
    checkout_url: str
    plan_id: int
    plan_nombre: str
    monto: Decimal


class ConfirmarPagoRequest(BaseModel):
    """[Segundo Parcial] CU02 - Confirmación de pago (simulación Stripe Billing)."""
    plan_id: int = Field(..., gt=0)
    payment_status: str = Field(..., min_length=1)  # ej: 'success'


class PagoHistorialRead(BaseModel):
    """Historial de pagos/suscripciones de la empresa (CU02)."""
    id: int
    plan_id: int
    plan_nombre: str
    precio_mensual: Decimal
    fecha_inicio: datetime
    fecha_fin: datetime | None = None
    estado: str
