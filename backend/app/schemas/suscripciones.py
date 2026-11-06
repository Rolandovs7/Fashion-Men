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
