from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class InventarioCrear(BaseModel):
    variante_id: int
    sucursal_id: int
    cantidad: int = Field(..., ge=0)
    cantidad_reservada: int = Field(0, ge=0)


class InventarioActualizar(BaseModel):
    cantidad: Optional[int] = Field(None, ge=0)
    cantidad_reservada: Optional[int] = Field(None, ge=0)


class InventarioRespuesta(BaseModel):
    id: int
    variante_id: int
    sucursal_id: int
    cantidad: int
    cantidad_reservada: int
    producto_nombre: Optional[str] = None
    producto_imagen_url: Optional[str] = None
    variante_talla: Optional[str] = None
    variante_color: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)