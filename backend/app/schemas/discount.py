from datetime import date
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class DescuentoCrear(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=100)
    porcentaje: float = Field(..., gt=0, le=100)
    fecha_inicio: Optional[date] = None
    fecha_fin: Optional[date] = None


class DescuentoActualizar(BaseModel):
    nombre: Optional[str] = Field(None, min_length=1, max_length=100)
    porcentaje: Optional[float] = Field(None, gt=0, le=100)
    fecha_inicio: Optional[date] = None
    fecha_fin: Optional[date] = None
    activo: Optional[bool] = None


class DescuentoRespuesta(BaseModel):
    id: int
    nombre: str
    porcentaje: float
    fecha_inicio: Optional[date] = None
    fecha_fin: Optional[date] = None
    activo: bool

    model_config = ConfigDict(from_attributes=True)
