# ============================================================
# TRAZABILIDAD MENSTYLE
# CU: CU29 - Visualizar Dashboard
# CU: CU30 - Generar Reportes
# RF: RF24 - Consultar reportes de ventas e inventario
# CAPA: Backend FastAPI (Service)
# ============================================================
from typing import List, Optional
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import func, desc, extract

from app.models.order import Pedido
from app.models.order_detail import DetallePedido
from app.models.product import Producto
from app.models.product_variant import ProductoVariante
from app.models.branch import Sucursal
from app.models.inventory import Inventario
from app.models.payment import Pago
from app.models.user import Usuario


class ReportService:
    """Genera reportes consolidados de ventas e inventario (RF24)."""

    def __init__(self, db: Session):
        self.db = db

    # ========================================================
    # KPIs Dashboard (CU29)
    # ========================================================
    def dashboard_kpis(self) -> dict:
        """Totales generales para el dashboard ejecutivo."""

        # Total ventas (pedidos no cancelados)
        total_ventas = (
            self.db.query(func.coalesce(func.sum(Pedido.total), 0))
            .filter(Pedido.estado != "cancelado")
            .scalar()
        )

        # Total pedidos
        total_pedidos = self.db.query(func.count(Pedido.id)).scalar()

        # Total productos activos
        total_productos = (
            self.db.query(func.count(Producto.id))
            .filter(Producto.activo == True)
            .scalar()
        )

        # Total sucursales activas
        total_sucursales = (
            self.db.query(func.count(Sucursal.id))
            .filter(Sucursal.activo == True)
            .scalar()
        )

        # Productos con stock bajo (<5 unidades disponibles)
        productos_bajo_stock = (
            self.db.query(func.count(Inventario.id))
            .filter((Inventario.cantidad - Inventario.cantidad_reservada) < 5)
            .scalar()
        )

        # Clientes registrados (rol cliente)
        clientes_registrados = (
            self.db.query(func.count(Usuario.id))
            .filter(Usuario.rol == "cliente")
            .scalar()
        )

        return {
            "total_ventas": float(total_ventas or 0),
            "total_pedidos": int(total_pedidos or 0),
            "total_productos": int(total_productos or 0),
            "total_sucursales": int(total_sucursales or 0),
            "productos_bajo_stock": int(productos_bajo_stock or 0),
            "clientes_registrados": int(clientes_registrados or 0),
        }

    # ========================================================
    # Productos Top (CU30)
    # ========================================================
    def productos_top(self, limite: int = 10) -> List[dict]:
        """Top N productos más vendidos."""
        resultados = (
            self.db.query(
                Producto.id.label("producto_id"),
                Producto.nombre.label("nombre"),
                func.sum(DetallePedido.cantidad).label("total_vendido"),
                func.sum(DetallePedido.subtotal).label("ingresos"),
            )
            .join(ProductoVariante, ProductoVariante.producto_id == Producto.id)
            .join(DetallePedido, DetallePedido.variante_id == ProductoVariante.id)
            .join(Pedido, Pedido.id == DetallePedido.pedido_id)
            .filter(Pedido.estado != "cancelado")
            .group_by(Producto.id, Producto.nombre)
            .order_by(desc("total_vendido"))
            .limit(limite)
            .all()
        )

        return [
            {
                "producto_id": r.producto_id,
                "nombre": r.nombre,
                "total_vendido": int(r.total_vendido or 0),
                "ingresos": float(r.ingresos or 0),
            }
            for r in resultados
        ]

    # ========================================================
    # Ventas por mes (CU30)
    # ========================================================
    def ventas_por_mes(self, meses: int = 12) -> List[dict]:
        """Ventas agrupadas por mes (últimos N meses)."""
        fecha_limite = datetime.utcnow() - timedelta(days=30 * meses)

        resultados = (
            self.db.query(
                extract("year", Pedido.fecha_pedido).label("anio"),
                extract("month", Pedido.fecha_pedido).label("mes_num"),
                func.sum(Pedido.total).label("total"),
                func.count(Pedido.id).label("cantidad_pedidos"),
            )
            .filter(Pedido.fecha_pedido >= fecha_limite)
            .filter(Pedido.estado != "cancelado")
            .group_by("anio", "mes_num")
            .order_by("anio", "mes_num")
            .all()
        )

        return [
            {
                "mes": f"{int(r.anio)}-{int(r.mes_num):02d}",
                "total": float(r.total or 0),
                "cantidad_pedidos": int(r.cantidad_pedidos or 0),
            }
            for r in resultados
        ]

    # ========================================================
    # Ventas por método de pago (CU30)
    # ========================================================
    def ventas_por_metodo_pago(self) -> List[dict]:
        """Ventas agrupadas por método de pago."""
        resultados = (
            self.db.query(
                Pago.metodo.label("metodo"),
                func.sum(Pago.monto).label("total"),
                func.count(Pago.id).label("cantidad"),
            )
            .filter(Pago.estado == "completado")
            .group_by(Pago.metodo)
            .order_by(desc("total"))
            .all()
        )

        return [
            {
                "metodo": r.metodo,
                "total": float(r.total or 0),
                "cantidad": int(r.cantidad or 0),
            }
            for r in resultados
        ]

    # ========================================================
    # Inventario bajo (CU30)
    # ========================================================
    def inventario_bajo(self, umbral: int = 5, limite: int = 20) -> List[dict]:
        """Productos con stock disponible bajo el umbral."""
        resultados = (
            self.db.query(
                Inventario.id.label("inventario_id"),
                Inventario.variante_id,
                ProductoVariante.producto_id,
                Producto.nombre.label("producto_nombre"),
                Sucursal.nombre.label("sucursal"),
                Inventario.cantidad,
                Inventario.cantidad_reservada,
            )
            .join(ProductoVariante, ProductoVariante.id == Inventario.variante_id)
            .join(Producto, Producto.id == ProductoVariante.producto_id)
            .join(Sucursal, Sucursal.id == Inventario.sucursal_id)
            .filter((Inventario.cantidad - Inventario.cantidad_reservada) < umbral)
            .order_by((Inventario.cantidad - Inventario.cantidad_reservada).asc())
            .limit(limite)
            .all()
        )

        return [
            {
                "variante_id": r.variante_id,
                "producto_id": r.producto_id,
                "producto_nombre": r.producto_nombre,
                "sucursal": r.sucursal,
                "cantidad": int(r.cantidad or 0),
                "cantidad_reservada": int(r.cantidad_reservada or 0),
                "cantidad_disponible": int((r.cantidad or 0) - (r.cantidad_reservada or 0)),
            }
            for r in resultados
        ]

    # ========================================================
    # Ventas por sucursal (CU30)
    # ========================================================
    def ventas_por_sucursal(self) -> List[dict]:
        """
        Ventas agrupadas por sucursal.
        Como Pedido NO tiene sucursal_id, se calcula vía Inventario:
        Pedido -> DetallePedido -> variante_id -> Inventario.sucursal_id
        """
        resultados = (
            self.db.query(
                Sucursal.id.label("sucursal_id"),
                Sucursal.nombre.label("sucursal"),
                Sucursal.ciudad,
                func.sum(DetallePedido.subtotal).label("total_ventas"),
                func.sum(DetallePedido.cantidad).label("cantidad_vendida"),
            )
            .join(Inventario, Inventario.sucursal_id == Sucursal.id)
            .join(ProductoVariante, ProductoVariante.id == Inventario.variante_id)
            .join(DetallePedido, DetallePedido.variante_id == ProductoVariante.id)
            .join(Pedido, Pedido.id == DetallePedido.pedido_id)
            .filter(Pedido.estado != "cancelado")
            .group_by(Sucursal.id, Sucursal.nombre, Sucursal.ciudad)
            .order_by(desc("total_ventas"))
            .all()
        )

        return [
            {
                "sucursal_id": r.sucursal_id,
                "sucursal": r.sucursal,
                "ciudad": r.ciudad,
                "total_ventas": float(r.total_ventas or 0),
                "cantidad_vendida": int(r.cantidad_vendida or 0),
            }
            for r in resultados
        ]