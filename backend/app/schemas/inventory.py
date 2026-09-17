from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class InventarioCrear(BaseModel):
    variante_id: int
    sucursal_id: int
    cantidad: int = Field(..., ge=0)
    cantidad_reservada: int = Field(0, ge=0)


class InventarioActualizar(BaseModel):
    cantidad: Optional[int] = Field(None, ge=0)
    cantidad_reservada: Optional[int] = Field(None, ge=0)


class InventarioRespuesta(BaseModel):
    id: int
    variante_id: int
    sucursal_id: int
    cantidad: int
    cantidad_reservada: int

    model_config = ConfigDict(from_attributes=True)