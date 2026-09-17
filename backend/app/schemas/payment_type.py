from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class TipoPagoCrear(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=30)


class TipoPagoActualizar(BaseModel):
    nombre: Optional[str] = Field(None, min_length=1, max_length=30)
    activo: Optional[bool] = None


class TipoPagoRespuesta(BaseModel):
    id: int
    nombre: str
    activo: bool

    model_config = ConfigDict(from_attributes=True)
