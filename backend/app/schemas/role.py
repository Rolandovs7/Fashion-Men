from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class RolCrear(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=30)
    descripcion: Optional[str] = Field(None, max_length=150)


class RolActualizar(BaseModel):
    nombre: Optional[str] = Field(None, min_length=1, max_length=30)
    descripcion: Optional[str] = Field(None, max_length=150)
    activo: Optional[bool] = None


class RolRespuesta(BaseModel):
    id: int
    nombre: str
    descripcion: Optional[str] = None
    activo: bool

    model_config = ConfigDict(from_attributes=True)
