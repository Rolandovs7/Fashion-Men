# ============================================================
# TRAZABILIDAD MENSTYLE
# CU: CU31 - Recibir Recomendaciones (IA)
# CU: CU32 - Interactuar con Asistente Virtual
# RF: RF25 - Proporcionar funcionalidad basada en inteligencia artificial
# CAPA: Backend FastAPI (Schemas)
# ============================================================
from pydantic import BaseModel, Field
from typing import Optional, List


class RecomendacionRequest(BaseModel):
    """Request para solicitar recomendaciones personalizadas."""
    categoria_id: Optional[int] = Field(None, description="Filtrar por categoría")
    tipo_prenda_id: Optional[int] = Field(None, description="Filtrar por tipo de prenda")
    limite: int = Field(5, ge=1, le=20, description="Número de recomendaciones")

    class Config:
        json_schema_extra = {
            "example": {
                "categoria_id": 1,
                "limite": 5
            }
        }


class ProductoRecomendado(BaseModel):
    """Producto individual en la respuesta de recomendaciones."""
    id: int
    nombre: str
    descripcion: Optional[str] = None
    precio: float
    categoria_id: Optional[int] = None
    motivo: str = Field(..., description="Por qué se recomienda este producto")


class RecomendacionResponse(BaseModel):
    """Respuesta con lista de productos recomendados."""
    usuario_id: Optional[int] = None
    total: int
    recomendaciones: List[ProductoRecomendado]


class ChatRequest(BaseModel):
    """Request para interactuar con el asistente virtual."""
    mensaje: str = Field(..., min_length=1, max_length=500)

    class Config:
        json_schema_extra = {
            "example": {
                "mensaje": "Busco un traje formal para una boda"
            }
        }


class ChatResponse(BaseModel):
    """Respuesta del asistente virtual."""
    respuesta: str
    productos_sugeridos: List[ProductoRecomendado] = []


class TendenciaResponse(BaseModel):
    """Productos más vendidos / tendencias."""
    total: int
    productos: List[ProductoRecomendado]