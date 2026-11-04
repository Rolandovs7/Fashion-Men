# ============================================================
# TRAZABILIDAD MENSTYLE
# CU: CU29 - Visualizar Dashboard
# CU: CU30 - Generar Reportes
# RF: RF24 - Consultar reportes de ventas e inventario
# CAPA: Backend FastAPI (Service)
# ============================================================
from typing import List, Optional
from datetime import datetime, timedelta
import time

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


_CACHE = {}
_CACHE_TTL = 60


class ReportService:
    """Genera reportes consolidados de ventas e inventario (RF24)."""

    def __init__(self, db: Session):
        self.db = db

    def _cache_get(self, key):
        item = _CACHE.get(key)
        if not item:
            return None
        if time.time() - item[0] > _CACHE_TTL:
            _CACHE.pop(key, None)
            return None
        return item[1]

    def _cache_set(self, key, value):
        _CACHE[key] = (time.time(), value)

    # ========================================================
    # KPIs Dashboard (CU29)
    # ========================================================
    def dashboard_kpis(self, empresa_id: int | None = None) -> dict:
        """Totales generales para el dashboard ejecutivo."""
        key = f"dashboard_{empresa_id}"
        cached = self._cache_get(key)
        if cached is not None:
            return cached

        q_ventas = self.db.query(func.coalesce(func.sum(Pedido.total), 0)).filter(Pedido.estado != "cancelado")
        if empresa_id is not None:
            q_ventas = q_ventas.filter(Pedido.empresa_id == empresa_id)
        total_ventas = q_ventas.scalar()

        q_pedidos = self.db.query(func.count(Pedido.id))
        if empresa_id is not None:
            q_pedidos = q_pedidos.filter(Pedido.empresa_id == empresa_id)
        total_pedidos = q_pedidos.scalar()

        q_productos = self.db.query(func.count(Producto.id)).filter(Producto.activo == True)
        if empresa_id is not None:
            q_productos = q_productos.filter(Producto.empresa_id == empresa_id)
        total_productos = q_productos.scalar()

        q_sucursales = self.db.query(func.count(Sucursal.id)).filter(Sucursal.activo == True)
        if empresa_id is not None:
            q_sucursales = q_sucursales.filter(Sucursal.empresa_id == empresa_id)
        total_sucursales = q_sucursales.scalar()

        q_bajo = (
            self.db.query(func.count(Inventario.id))
            .join(Sucursal, Sucursal.id == Inventario.sucursal_id)
            .filter((Inventario.cantidad - Inventario.cantidad_reservada) < 5)
        )
        if empresa_id is not None:
            q_bajo = q_bajo.filter(Sucursal.empresa_id == empresa_id)
        productos_bajo_stock = q_bajo.scalar()

        q_clientes = self.db.query(func.count(Usuario.id)).filter(Usuario.rol == "cliente")
        if empresa_id is not None:
            q_clientes = q_clientes.filter(Usuario.empresa_id == empresa_id)
        clientes_registrados = q_clientes.scalar()

        res = {
            "total_ventas": float(total_ventas or 0),
            "total_pedidos": int(total_pedidos or 0),
            "total_productos": int(total_productos or 0),
            "total_sucursales": int(total_sucursales or 0),
            "productos_bajo_stock": int(productos_bajo_stock or 0),
            "clientes_registrados": int(clientes_registrados or 0),
        }
        self._cache_set(key, res)
        return res

    # ========================================================
    # Productos Top (CU30)
    # ========================================================
    def productos_top(self, limite: int = 10, empresa_id: int | None = None) -> List[dict]:
        """Top N productos más vendidos (detalle profesional)."""
        from app.models.user import Usuario
        from app.models.payment import Pago

        q = (
            self.db.query(
                Pedido.id.label("pedido_id"),
                Pedido.fecha_pedido.label("fecha"),
                Sucursal.nombre.label("sucursal"),
                Usuario.nombre.label("cliente_nombre"),
                Usuario.apellido.label("cliente_apellido"),
                Pago.metodo.label("metodo_pago"),
                Producto.id.label("producto_id"),
                Producto.nombre.label("nombre"),
                DetallePedido.cantidad.label("cantidad"),
                DetallePedido.subtotal.label("ingresos"),
            )
            .join(ProductoVariante, ProductoVariante.id == DetallePedido.variante_id)
            .join(Producto, Producto.id == ProductoVariante.producto_id)
            .join(Pedido, Pedido.id == DetallePedido.pedido_id)
            .outerjoin(Sucursal, Sucursal.id == Pedido.sucursal_id)
            .outerjoin(Usuario, Usuario.id == Pedido.usuario_id)
            .outerjoin(Pago, Pago.pedido_id == Pedido.id)
            .filter(Pedido.estado != "cancelado")
        )
        if empresa_id is not None:
            q = q.filter(Pedido.empresa_id == empresa_id)
        resultados = q.order_by(Pedido.fecha_pedido.desc()).limit(limite * 10).all()

        total_general = 0.0
        total_prendas = 0
        items = []
        for r in resultados:
            total_general += float(r.ingresos or 0)
            total_prendas += int(r.cantidad or 0)
            cliente = ""
            if r.cliente_nombre:
                cliente = f"{r.cliente_nombre} {r.cliente_apellido or ''}".strip()
            items.append({
                "pedido_id": r.pedido_id,
                "fecha": r.fecha.strftime("%Y-%m-%d %H:%M") if r.fecha else "",
                "sucursal": r.sucursal or "",
                "cliente": cliente,
                "metodo_pago": r.metodo_pago or "",
                "producto_id": r.producto_id,
                "nombre": r.nombre,
                "cantidad": int(r.cantidad or 0),
                "ingresos": float(r.ingresos or 0),
                "total_vendido": int(r.cantidad or 0),
            })
            if len(items) >= limite:
                break

        return items

    # ========================================================
    # Ventas por mes (CU30)
    # ========================================================
    def ventas_por_mes(self, meses: int = 12, empresa_id: int | None = None) -> List[dict]:
        """Ventas agrupadas por mes (últimos N meses)."""
        fecha_limite = datetime.utcnow() - timedelta(days=30 * meses)

        q = (
            self.db.query(
                extract("year", Pedido.fecha_pedido).label("anio"),
                extract("month", Pedido.fecha_pedido).label("mes_num"),
                func.sum(Pedido.total).label("total"),
                func.count(Pedido.id).label("cantidad_pedidos"),
            )
            .filter(Pedido.fecha_pedido >= fecha_limite)
            .filter(Pedido.estado != "cancelado")
        )
        if empresa_id is not None:
            q = q.filter(Pedido.empresa_id == empresa_id)
        resultados = (
            q.group_by("anio", "mes_num")
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
    def ventas_por_metodo_pago(self, empresa_id: int | None = None) -> List[dict]:
        """Ventas agrupadas por método de pago."""
        key = f"ventas_metodo_{empresa_id}"
        cached = self._cache_get(key)
        if cached is not None:
            return cached
        q = (
            self.db.query(
                Pago.metodo.label("metodo"),
                func.sum(Pago.monto).label("total"),
                func.count(Pago.id).label("cantidad"),
            )
            .join(Pedido, Pedido.id == Pago.pedido_id)
            .filter(Pago.estado == "completado")
        )
        if empresa_id is not None:
            q = q.filter(Pedido.empresa_id == empresa_id)
        resultados = (
            q.group_by(Pago.metodo)
            .order_by(desc("total"))
            .all()
        )

        res = [
            {
                "metodo": r.metodo,
                "total": float(r.total or 0),
                "cantidad": int(r.cantidad or 0),
            }
            for r in resultados
        ]
        self._cache_set(key, res)
        return res

    # ========================================================
    # Inventario bajo (CU30)
    # ========================================================
    def inventario_bajo(self, umbral: int = 5, limite: int = 20, empresa_id: int | None = None) -> List[dict]:
        """Productos con stock disponible bajo el umbral."""
        key = f"inventario_bajo_{empresa_id}_{umbral}_{limite}"
        cached = self._cache_get(key)
        if cached is not None:
            return cached

        subq_prod = self.db.query(Producto.id)
        if empresa_id is not None:
            subq_prod = subq_prod.filter(Producto.empresa_id == empresa_id)
        subq_var = self.db.query(ProductoVariante.id).filter(ProductoVariante.producto_id.in_(subq_prod))
        subq_inv = self.db.query(Inventario).filter(Inventario.variante_id.in_(subq_var))

        resultados = []
        for inv in subq_inv.all():
            disponible = int((inv.cantidad or 0) - (inv.cantidad_reservada or 0))
            if disponible < umbral:
                var = self.db.query(ProductoVariante).filter(ProductoVariante.id == inv.variante_id).first()
                prod = self.db.query(Producto).filter(Producto.id == var.producto_id).first() if var else None
                suc = self.db.query(Sucursal).filter(Sucursal.id == inv.sucursal_id).first()
                if empresa_id is not None and suc and suc.empresa_id != empresa_id:
                    continue
                resultados.append({
                    "variante_id": inv.variante_id,
                    "producto_id": prod.id if prod else 0,
                    "producto_nombre": prod.nombre if prod else "",
                    "sucursal": suc.nombre if suc else "",
                    "cantidad": int(inv.cantidad or 0),
                    "cantidad_reservada": int(inv.cantidad_reservada or 0),
                    "cantidad_disponible": disponible,
                })
        resultados = sorted(resultados, key=lambda x: x["cantidad_disponible"])[:limite]
        self._cache_set(key, resultados)
        return resultados

    # ========================================================
    # Ventas por sucursal (CU30)
    # ========================================================
    def ventas_por_sucursal(self, empresa_id: int | None = None) -> List[dict]:
        """
        Ventas agrupadas por sucursal.
        Como Pedido NO tiene sucursal_id, se calcula vía Inventario:
        Pedido -> DetallePedido -> variante_id -> Inventario.sucursal_id
        """
        q = (
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
        )
        if empresa_id is not None:
            q = q.filter(Sucursal.empresa_id == empresa_id)
        resultados = (
            q.group_by(Sucursal.id, Sucursal.nombre, Sucursal.ciudad)
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