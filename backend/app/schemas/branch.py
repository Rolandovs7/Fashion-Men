from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class SucursalCrear(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=100)
    direccion: str = Field(..., min_length=1, max_length=255)
    ciudad: str = Field(..., min_length=1, max_length=100)
    telefono: Optional[str] = Field(None, max_length=30)


class SucursalActualizar(BaseModel):
    nombre: Optional[str] = Field(None, min_length=1, max_length=100)
    direccion: Optional[str] = Field(None, min_length=1, max_length=255)
    ciudad: Optional[str] = Field(None, min_length=1, max_length=100)
    telefono: Optional[str] = Field(None, max_length=30)
    activo: Optional[bool] = None


class SucursalRespuesta(BaseModel):
    id: int
    nombre: str
    direccion: str
    ciudad: str
    telefono: Optional[str] = None
    activo: bool

    model_config = ConfigDict(from_attributes=True)
