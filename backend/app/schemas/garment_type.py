from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class TipoPrendaCrear(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=100)
    descripcion: Optional[str] = Field(None, max_length=255)


class TipoPrendaActualizar(BaseModel):
    nombre: Optional[str] = Field(None, min_length=1, max_length=100)
    descripcion: Optional[str] = Field(None, max_length=255)
    activo: Optional[bool] = None


class TipoPrendaRespuesta(BaseModel):
    id: int
    nombre: str
    descripcion: Optional[str] = None
    activo: bool

    model_config = ConfigDict(from_attributes=True)
