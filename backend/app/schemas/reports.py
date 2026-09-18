# ============================================================
# TRAZABILIDAD MENSTYLE
# CU: CU29 - Visualizar Dashboard
# CU: CU30 - Generar Reportes
# RF: RF24 - Consultar reportes de ventas e inventario
# CAPA: Backend FastAPI (Schemas)
# ============================================================
from pydantic import BaseModel
from typing import List


class DashboardResponse(BaseModel):
    """KPIs principales para el dashboard ejecutivo."""
    total_ventas: float
    total_pedidos: int
    total_productos: int
    total_sucursales: int
    productos_bajo_stock: int
    clientes_registrados: int


class ProductoTopResponse(BaseModel):
    """Producto en el top de ventas."""
    producto_id: int
    nombre: str
    total_vendido: int
    ingresos: float


class VentaMesResponse(BaseModel):
    """Ventas agrupadas por mes."""
    mes: str
    total: float
    cantidad_pedidos: int


class VentaMetodoPagoResponse(BaseModel):
    """Ventas agrupadas por método de pago."""
    metodo: str
    total: float
    cantidad: int


class InventarioBajoResponse(BaseModel):
    """Registro de inventario bajo el umbral."""
    variante_id: int
    producto_id: int
    producto_nombre: str
    sucursal: str
    cantidad: int
    cantidad_reservada: int
    cantidad_disponible: int


class VentaSucursalResponse(BaseModel):
    """Ventas agrupadas por sucursal."""
    sucursal_id: int
    sucursal: str
    ciudad: str
    total_ventas: float
    cantidad_vendida: int