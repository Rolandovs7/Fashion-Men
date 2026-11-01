"""
[Segundo Parcial] CU20 - Sincronización offline
[Segundo Parcial] CU21 - Resolución de conflictos de stock
[Segundo Parcial] RNF05 - Idempotencia
[Segundo Parcial] RNF06 - No eliminar operaciones en caso de fallo
"""
import logging
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, obtener_usuario_actual, get_current_empresa_id
from app.models.branch import Sucursal
from app.models.inventory import Inventario
from app.models.order import Pedido
from app.models.order_detail import DetallePedido
from app.models.product import Producto
from app.models.product_variant import ProductoVariante
from app.models.reservation import Reserva
from app.models.reservation_detail import DetalleReserva
from app.models.user import Usuario

router = APIRouter(tags=["Sincronización"])

logger = logging.getLogger(__name__)


@router.post("/operaciones")
def sincronizar_operaciones(
    operaciones: List[dict],
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU20 - Sincronización offline
    [Segundo Parcial] RNF05 - Idempotencia
    """
    resultados = []

    for op in operaciones:
        uuid_offline = op.get("uuid") or op.get("uuid_offline")
        tipo = op.get("tipo")
        try:
            if not uuid_offline or not tipo:
                resultados.append({"uuid": uuid_offline, "estado": "ERROR", "motivo": "Datos incompletos"})
                continue

            if tipo == "venta":
                existe = db.query(Pedido).filter(Pedido.uuid_offline == uuid_offline).first()
                if existe:
                    resultados.append({"uuid": uuid_offline, "estado": "ya_sincronizado", "pedido_id": existe.id})
                    continue

                sucursal_id = op.get("sucursal_id") or usuario_actual.sucursal_id
                sucursal = db.query(Sucursal).filter(Sucursal.id == sucursal_id).first() if sucursal_id else None
                if not sucursal or sucursal.empresa_id != empresa_id:
                    resultados.append({"uuid": uuid_offline, "estado": "ERROR", "motivo": "Sucursal no válida para la empresa"})
                    continue

                pedido = Pedido(
                    usuario_id=usuario_actual.id,
                    sucursal_id=sucursal.id,
                    empresa_id=empresa_id,
                    uuid_offline=uuid_offline,
                    fecha_pedido=datetime.utcnow(),
                    estado="pendiente",
                    total=op.get("monto") or 0
                )
                db.add(pedido)
                db.flush()

                detalles = op.get("productos") or op.get("items") or []
                conflicto = False
                for det in detalles:
                    variante_id = det.get("variante_id") or det.get("id")
                    cantidad = int(det.get("cantidad") or 1)
                    variante = db.query(ProductoVariante).filter(ProductoVariante.id == variante_id).first()
                    if not variante:
                        continue
                    producto = db.query(Producto).filter(Producto.id == variante.producto_id).first()
                    if not producto or producto.empresa_id != empresa_id:
                        continue
                    inventario = db.query(Inventario).filter(
                        Inventario.sucursal_id == sucursal.id,
                        Inventario.variante_id == variante.id
                    ).first()
                    stock_actual = inventario.cantidad if inventario else 0
                    if stock_actual < cantidad:
                        conflicto = True
                        cantidad_a_restar = stock_actual
                        if inventario:
                            inventario.cantidad = max(0, stock_actual - cantidad_a_restar)
                    else:
                        if inventario:
                            inventario.cantidad = stock_actual - cantidad
                    detalle = DetallePedido(
                        pedido_id=pedido.id,
                        variante_id=variante.id,
                        cantidad=cantidad,
                        precio_unitario=det.get("precio_unitario") or det.get("precio") or producto.precio,
                        subtotal=(det.get("precio_unitario") or det.get("precio") or producto.precio) * cantidad
                    )
                    db.add(detalle)

                if conflicto:
                    pedido.estado = "Procesada con Conflicto"
                    logger.warning(f"[SYNC][CONFLICTO] Pedido offline {uuid_offline} procesado con conflicto de stock para empresa {empresa_id}")
                    resultados.append({"uuid": uuid_offline, "estado": "CONFLICTO", "pedido_id": pedido.id})
                else:
                    pedido.estado = "Confirmada"
                    resultados.append({"uuid": uuid_offline, "estado": "SINCRONIZADO", "pedido_id": pedido.id})
                db.commit()
                continue

            if tipo == "reserva":
                existe = db.query(Reserva).filter(Reserva.uuid_offline == uuid_offline).first()
                if existe:
                    resultados.append({"uuid": uuid_offline, "estado": "ya_sincronizado", "reserva_id": existe.id})
                    continue

                sucursal_id = op.get("sucursal_id") or usuario_actual.sucursal_id
                sucursal = db.query(Sucursal).filter(Sucursal.id == sucursal_id).first() if sucursal_id else None
                if not sucursal or sucursal.empresa_id != empresa_id:
                    resultados.append({"uuid": uuid_offline, "estado": "ERROR", "motivo": "Sucursal no válida para la empresa"})
                    continue

                reserva = Reserva(
                    usuario_id=usuario_actual.id,
                    sucursal_id=sucursal.id,
                    empresa_id=empresa_id,
                    uuid_offline=uuid_offline,
                    fecha_reserva=datetime.utcnow(),
                    estado="Confirmada",
                    observaciones="Sincronizada desde modo offline"
                )
                db.add(reserva)
                db.flush()

                detalles = op.get("productos") or op.get("items") or []
                for det in detalles:
                    variante_id = det.get("variante_id") or det.get("id")
                    cantidad = int(det.get("cantidad") or 1)
                    variante = db.query(ProductoVariante).filter(ProductoVariante.id == variante_id).first()
                    if not variante:
                        continue
                    producto = db.query(Producto).filter(Producto.id == variante.producto_id).first()
                    if not producto or producto.empresa_id != empresa_id:
                        continue
                    detalle = DetalleReserva(
                        reserva_id=reserva.id,
                        variante_id=variante.id,
                        cantidad=cantidad
                    )
                    db.add(detalle)

                db.commit()
                resultados.append({"uuid": uuid_offline, "estado": "SINCRONIZADO", "reserva_id": reserva.id})
                continue

            resultados.append({"uuid": uuid_offline, "estado": "ERROR", "motivo": "Tipo no soportado"})
        except Exception as e:
            db.rollback()
            logger.exception(f"[SYNC][ERROR] Fallo al sincronizar {uuid_offline}: {e}")
            resultados.append({"uuid": uuid_offline, "estado": "ERROR", "motivo": str(e)})

    return {"resultados": resultados}
