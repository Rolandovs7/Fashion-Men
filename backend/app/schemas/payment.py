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