from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class DevolucionSolicitar(BaseModel):
    pedido_id: int = Field(..., gt=0)
    variante_id: int = Field(..., gt=0)
    cantidad: int = Field(..., gt=0)
    motivo: str = Field(..., min_length=1, max_length=255)


class DevolucionCambiarEstadoAdmin(BaseModel):
    nuevo_estado: str = Field(..., min_length=1, max_length=30)
    sucursal_id: Optional[int] = Field(None, gt=0)


class DevolucionRespuesta(BaseModel):
    id: int
    pedido_id: int
    variante_id: int
    cantidad: int
    motivo: str
    estado: str
    fecha_devolucion: datetime

    model_config = ConfigDict(from_attributes=True)