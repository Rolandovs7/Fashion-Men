from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field


class DetalleReservaItemCrear(BaseModel):
    variante_id: int
    cantidad: int = Field(..., gt=0)


class ReservaCrear(BaseModel):
    sucursal_id: int
    fecha_reserva: datetime
    observaciones: Optional[str] = Field(None, max_length=255)
    detalles: List[DetalleReservaItemCrear] = Field(..., min_length=1)


class ReservaCambiarEstado(BaseModel):
    nuevo_estado: str = Field(..., min_length=1, max_length=30)


class DetalleReservaRespuesta(BaseModel):
    id: int
    reserva_id: int
    variante_id: int
    cantidad: int

    model_config = ConfigDict(from_attributes=True)


class ReservaRespuesta(BaseModel):
    id: int
    usuario_id: int
    sucursal_id: int
    fecha_reserva: datetime
    estado: str
    observaciones: Optional[str] = None
    detalles: List[DetalleReservaRespuesta] = []

    model_config = ConfigDict(from_attributes=True)