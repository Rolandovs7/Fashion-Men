from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class TallaCrear(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=20)


class TallaActualizar(BaseModel):
    nombre: Optional[str] = Field(None, min_length=1, max_length=20)
    activo: Optional[bool] = None


class TallaRespuesta(BaseModel):
    id: int
    nombre: str
    activo: bool

    model_config = ConfigDict(from_attributes=True)
