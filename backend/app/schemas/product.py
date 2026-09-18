from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class ProductoBase(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=150)
    descripcion: Optional[str] = None
    imagen_url: Optional[str] = Field(None, max_length=500)
    precio: float = Field(..., gt=0)
    categoria_id: int
    proveedor_id: Optional[int] = None
    temporada_id: Optional[int] = None
    coleccion_id: Optional[int] = None
    tipo_prenda_id: Optional[int] = None
    marca_id: Optional[int] = None
    descuento_id: Optional[int] = None


class ProductoCrear(ProductoBase):
    pass


class ProductoActualizar(BaseModel):
    nombre: Optional[str] = Field(None, min_length=1, max_length=150)
    descripcion: Optional[str] = None
    imagen_url: Optional[str] = Field(None, max_length=500)
    precio: Optional[float] = Field(None, gt=0)
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

    model_config = ConfigDict(from_attributes=True)
