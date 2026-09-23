from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class VarianteCrear(BaseModel):
    producto_id: int
    talla_id: int
    color_id: int
    nombre_variante: Optional[str] = None
    imagen_url: Optional[str] = Field(None, max_length=500)


class VarianteActualizar(BaseModel):
    activo: Optional[bool] = None
    nombre_variante: Optional[str] = None
    imagen_url: Optional[str] = Field(None, max_length=500)


class VarianteRespuesta(BaseModel):
    id: int
    producto_id: int
    talla_id: int
    talla_nombre: str
    color_id: int
    color_nombre: str
    color_codigo_hex: Optional[str] = None
    color_imagen_url: Optional[str] = None
    nombre_variante: Optional[str] = None
    imagen_url: Optional[str] = None
    activo: bool
    stock_disponible: int = 0

    model_config = ConfigDict(from_attributes=True)
