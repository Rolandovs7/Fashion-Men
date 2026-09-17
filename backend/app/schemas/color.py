from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class ColorCrear(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=50)
    codigo_hex: Optional[str] = Field(None, max_length=7)


class ColorActualizar(BaseModel):
    nombre: Optional[str] = Field(None, min_length=1, max_length=50)
    codigo_hex: Optional[str] = Field(None, max_length=7)
    activo: Optional[bool] = None


class ColorRespuesta(BaseModel):
    id: int
    nombre: str
    codigo_hex: Optional[str] = None
    activo: bool

    model_config = ConfigDict(from_attributes=True)
