from typing import List
from pydantic import BaseModel, ConfigDict, Field


class DetalleCarritoCrear(BaseModel):
    variante_id: int
    cantidad: int = Field(..., gt=0)


class DetalleCarritoActualizar(BaseModel):
    cantidad: int = Field(..., gt=0)


class DetalleCarritoRespuesta(BaseModel):
    id: int
    carrito_id: int
    variante_id: int
    cantidad: int

    model_config = ConfigDict(from_attributes=True)


class CarritoRespuesta(BaseModel):
    id: int
    usuario_id: int
    detalles: List[DetalleCarritoRespuesta] = []

    model_config = ConfigDict(from_attributes=True)