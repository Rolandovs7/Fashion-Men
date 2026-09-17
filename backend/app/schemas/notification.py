from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class NotificacionCrear(BaseModel):
    usuario_id: int
    titulo: str = Field(..., min_length=1, max_length=150)
    mensaje: str = Field(..., min_length=1, max_length=500)


class NotificacionRespuesta(BaseModel):
    id: int
    usuario_id: int
    titulo: str
    mensaje: str
    leida: bool
    fecha_creacion: datetime

    model_config = ConfigDict(from_attributes=True)