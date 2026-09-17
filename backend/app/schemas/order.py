from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field


class PedidoCrear(BaseModel):
    sucursal_id: int = Field(..., gt=0)


class ItemVentaPresencial(BaseModel):
    variante_id: int = Field(..., gt=0)
    cantidad: int = Field(..., gt=0)


class VentaPresencialCrear(BaseModel):
    usuario_id: int = Field(..., gt=0)
    sucursal_id: int = Field(..., gt=0)
    metodo_pago: str = Field(..., min_length=1, max_length=30)
    items: List[ItemVentaPresencial] = Field(..., min_length=1)


class PedidoCambiarEstadoAdmin(BaseModel):
    nuevo_estado: str = Field(..., min_length=1, max_length=30)
    sucursal_id: Optional[int] = Field(None, gt=0)


class DetallePedidoRespuesta(BaseModel):
    id: int
    pedido_id: int
    variante_id: int
    cantidad: int
    precio_unitario: float
    subtotal: float

    model_config = ConfigDict(from_attributes=True)


class PedidoRespuesta(BaseModel):
    id: int
    usuario_id: int
    fecha_pedido: datetime
    estado: str
    total: float
    detalles: List[DetallePedidoRespuesta] = []

    model_config = ConfigDict(from_attributes=True)