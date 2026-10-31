"""
[Segundo Parcial] CU06 - Gestionar catálogo
[Segundo Parcial] CU27 - Gestionar listas de precios
"""
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class ProductoBase(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=150)
    descripcion: Optional[str] = None
    imagen_url: Optional[str] = Field(None, max_length=500)
    modelo_ar_url: Optional[str] = Field(None, max_length=500)
    precio: float = Field(..., gt=0)
    precio_mayorista: Optional[float] = Field(None, ge=0)
    cantidad_mayorista: Optional[int] = Field(None, ge=1)
    categoria_id: int
    proveedor_id: Optional[int] = None
    temporada_id: Optional[int] = None
    coleccion_id: Optional[int] = None
    tipo_prenda_id: Optional[int] = None
    marca_id: Optional[int] = None
    descuento_id: Optional[int] = None


class ProductoCrear(ProductoBase):
    activo: bool = True


class ProductoActualizar(BaseModel):
    nombre: Optional[str] = Field(None, min_length=1, max_length=150)
    descripcion: Optional[str] = None
    imagen_url: Optional[str] = Field(None, max_length=500)
    modelo_ar_url: Optional[str] = Field(None, max_length=500)
    precio: Optional[float] = Field(None, gt=0)
    precio_mayorista: Optional[float] = Field(None, ge=0)
    cantidad_mayorista: Optional[int] = Field(None, ge=1)
    categoria_id: Optional[int] = None
    proveedor_id: Optional[int] = None
    temporada_id: Optional[int] = None
    coleccion_id: Optional[int] = None
    tipo_prenda_id: Optional[int] = None
    marca_id: Optional[int] = None
    descuento_id: Optional[int] = None
    activo: Optional[bool] = None


class ProductoRespuesta(ProductoBase):
    id: int
    activo: bool
    empresa_id: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)
