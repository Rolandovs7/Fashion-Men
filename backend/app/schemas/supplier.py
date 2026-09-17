from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class ProveedorCrear(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=150)
    contacto: Optional[str] = Field(None, max_length=100)
    telefono: Optional[str] = Field(None, max_length=30)
    email: Optional[str] = Field(None, max_length=150)
    direccion: Optional[str] = Field(None, max_length=255)


class ProveedorActualizar(BaseModel):
    nombre: Optional[str] = Field(None, min_length=1, max_length=150)
    contacto: Optional[str] = Field(None, max_length=100)
    telefono: Optional[str] = Field(None, max_length=30)
    email: Optional[str] = Field(None, max_length=150)
    direccion: Optional[str] = Field(None, max_length=255)
    activo: Optional[bool] = None


class ProveedorRespuesta(BaseModel):
    id: int
    nombre: str
    contacto: Optional[str] = None
    telefono: Optional[str] = None
    email: Optional[str] = None
    direccion: Optional[str] = None
    activo: bool

    model_config = ConfigDict(from_attributes=True)
