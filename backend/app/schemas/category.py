from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class CategoriaBase(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=100)
    descripcion: Optional[str] = Field(None, max_length=255)


class CategoriaCrear(CategoriaBase):
    pass


class CategoriaActualizar(BaseModel):
    nombre: Optional[str] = Field(None, min_length=1, max_length=100)
    descripcion: Optional[str] = Field(None, max_length=255)
    activo: Optional[bool] = None


class CategoriaRespuesta(CategoriaBase):
    id: int
    activo: bool

    model_config = ConfigDict(from_attributes=True)