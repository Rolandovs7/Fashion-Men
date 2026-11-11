"""
Seed: datos de prueba (clientes, pedidos con detalles y pagos, reservas)
para TODAS las empresas activas del SaaS (MenStyle y Avenor, o las que
existan en la base de datos), con fechas distribuidas en los últimos
6 meses. Su objetivo es que los gráficos del Dashboard (ventas por mes,
ventas por empresa, ventas por sucursal, métodos de pago) tengan datos
realistas.

Características:
- IDEMPOTENTE: los datos de prueba se identifican por el dominio de email
  de los clientes seed (@menstyle.test). Al re-ejecutar, se borran los
  clientes seed anteriores con TODOS sus pedidos/detalles/pagos/reservas
  y se regeneran desde cero.
- NO toca inventario ni stock (los pedidos se insertan directamente como
  filas históricas, sin descuento de existencias).
- No modifica usuarios, productos ni empresas existentes.

Uso (local, usando .env/DATABASE_URL del proyecto):
  cd backend
  ../.venv/bin/python seed_datos_prueba.py

Uso contra Render (reemplaza con tu DATABASE_URL real de Render):
  cd backend
  DATABASE_URL='postgresql://USER:PASSWORD@HOST/DBNAME' ../.venv/bin/python seed_datos_prueba.py
"""

import os
import random
import sys
from datetime import datetime, timedelta

# Permite ejecutar como script desde la carpeta backend
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.database import SessionLocal
from app.core.security import obtener_password_hash
from app.models.saas import Empresa
from app.models.user import Usuario
from app.models.branch import Sucursal
from app.models.product import Producto
from app.models.product_variant import ProductoVariante
from app.models.order import Pedido
from app.models.order_detail import DetallePedido
from app.models.payment import Pago
from app.models.reservation import Reserva

# ---------------------------------------------------------------------------
# Configuración del seed
# ---------------------------------------------------------------------------
DOMINIO_SEED = "@menstyle.test"
PASSWORD_SEED = "Seed2026!"
MESES_HISTORIAL = 6
CLIENTES_POR_EMPRESA = 8
CLIENTES_BASE = [
    ("Mateo", "Fernández"), ("Lucas", "Vargas"), ("Diego", "Salazar"),
    ("Andrés", "Cordero",), ("Bruno", "Alanes"), ("Iván", "Rojas"),
    ("Samuel", "Paz"), ("Tomás", "Guzmán"),
]
PEDIDOS_POR_MES = (6, 12)          # rango aleatorio de pedidos por mes
DETALLES_POR_PEDIDO = (1, 4)       # rango de items por pedido
CANTIDAD_POR_DETALLE = (1, 3)      # rango de unidades por item
RESERVAS_POR_MES = (2, 5)          # rango de reservas por mes
METODOS_PAGO = ["tarjeta", "QR", "efectivo", "transferencia"]
ESTADOS_PEDIDO = [
    # (estado, peso) — los cancelados quedan excluidos de los reportes.
    ("entregado", 40), ("pagado", 25), ("procesando", 10),
    ("enviado", 10), ("pendiente", 10), ("cancelado", 5),
]
ESTADOS_RESERVA = [
    ("completada", 40), ("confirmada", 30), ("pendiente", 20), ("cancelada", 10),
]

random.seed(42)  # reproducibilidad entre ejecuciones


def _fecha_aleatoria_en_mes(hoy: datetime, meses_atras: int) -> datetime:
    """Fecha/hora aleatoria dentro del mes ubicado `meses_atras` atrás."""
    anio = hoy.year
    mes = hoy.month - meses_atras
    while mes <= 0:
        mes += 12
        anio -= 1
    dia_max = 28 if meses_atras > 0 else hoy.day  # seguro para cualquier mes
    return datetime(
        anio, mes, random.randint(1, max(1, dia_max)),
        random.randint(9, 21), random.randint(0, 59),
    )


def limpiar_seed_anterior(db) -> int:
    """Borra clientes seed y todos sus pedidos/pagos/reservas (idempotencia)."""
    usuarios_seed = (
        db.query(Usuario)
        .filter(Usuario.email.like(f"%{DOMINIO_SEED}"))
        .all()
    )
    if not usuarios_seed:
        return 0
    ids = [u.id for u in usuarios_seed]
    pedidos = db.query(Pedido).filter(Pedido.usuario_id.in_(ids)).all()
    pedido_ids = [p.id for p in pedidos]
    if pedido_ids:
        db.query(Pago).filter(Pago.pedido_id.in_(pedido_ids)).delete(synchronize_session=False)
        db.query(DetallePedido).filter(DetallePedido.pedido_id.in_(pedido_ids)).delete(synchronize_session=False)
        db.query(Pedido).filter(Pedido.id.in_(pedido_ids)).delete(synchronize_session=False)
    db.query(Reserva).filter(Reserva.usuario_id.in_(ids)).delete(synchronize_session=False)
    db.query(Usuario).filter(Usuario.id.in_(ids)).delete(synchronize_session=False)
    db.commit()
    return len(usuarios_seed)


def _crear_clientes_seed(db, empresa: Empresa) -> list[Usuario]:
    """Crea (o reutiliza) los clientes de prueba de la empresa."""
    clientes = []
    for i, (nombre, apellido) in enumerate(CLIENTES_BASE, start=1):
        email = f"cliente{i}.emp{empresa.id}{DOMINIO_SEED}"
        cliente = db.query(Usuario).filter(Usuario.email == email).first()
        if cliente is None:
            cliente = Usuario(
                nombre=nombre,
                apellido=apellido,
                email=email,
                password_hash=obtener_password_hash(PASSWORD_SEED),
                activo=True,
                rol="cliente",
                empresa_id=empresa.id,
            )
            db.add(cliente)
            db.flush()
        clientes.append(cliente)
    db.commit()
    return clientes


def _variantes_de_empresa(db, empresa: Empresa, es_principal: bool) -> list:
    """
    Variantes (con su producto) vendibles de la empresa.
    La empresa principal absorbe el catálogo legacy (productos con
    empresa_id NULL, creados antes del modelo multitenant).
    """
    from sqlalchemy import or_

    q = (
        db.query(ProductoVariante, Producto)
        .join(Producto, Producto.id == ProductoVariante.producto_id)
        .filter(Producto.activo == True)  # noqa: E712
    )
    if es_principal:
        q = q.filter(or_(Producto.empresa_id == empresa.id, Producto.empresa_id.is_(None)))
    else:
        q = q.filter(Producto.empresa_id == empresa.id)
    return q.all()


def _poblar_empresa(db, empresa: Empresa, hoy: datetime, es_principal: bool) -> dict:
    """Genera pedidos, pagos y reservas de prueba para una empresa."""
    sucursales = (
        db.query(Sucursal)
        .filter(Sucursal.empresa_id == empresa.id, Sucursal.activo == True)  # noqa: E712
        .all()
    )
    variantes = _variantes_de_empresa(db, empresa, es_principal)

    stats = {
        "empresa": empresa.nombre,
        "pedidos": 0, "detalles": 0, "pagos": 0,
        "reservas": 0, "clientes": 0,
        "omitida": False, "motivo": "",
    }

    if not variantes:
        stats["omitida"] = True
        stats["motivo"] = "sin productos/variantes activos"
        return stats

    clientes = _crear_clientes_seed(db, empresa)
    stats["clientes"] = len(clientes)

    if not clientes:
        stats["omitida"] = True
        stats["motivo"] = "no se pudieron crear clientes seed"
        return stats

    # ------------------------------------------------------------------
    # Pedidos + detalles + pagos (últimos MESES_HISTORIAL meses)
    # ------------------------------------------------------------------
    for meses_atras in range(MESES_HISTORIAL - 1, -1, -1):
        cantidad_pedidos = random.randint(*PEDIDOS_POR_MES)
        for _ in range(cantidad_pedidos):
            fecha = _fecha_aleatoria_en_mes(hoy, meses_atras)
            cliente = random.choice(clientes)
            estado = random.choices(
                [e for e, _ in ESTADOS_PEDIDO],
                weights=[w for _, w in ESTADOS_PEDIDO],
            )[0]
            sucursal = random.choice(sucursales) if sucursales else None

            pedido = Pedido(
                usuario_id=cliente.id,
                sucursal_id=sucursal.id if sucursal else None,
                empresa_id=empresa.id,
                fecha_pedido=fecha,
                estado=estado,
                total=0,
            )
            db.add(pedido)
            db.flush()

            total = 0.0
            cantidad_detalles = random.randint(*DETALLES_POR_PEDIDO)
            for _ in range(cantidad_detalles):
                variante, producto = random.choice(variantes)
                cantidad = random.randint(*CANTIDAD_POR_DETALLE)
                precio = float(producto.precio or 0)
                subtotal = round(precio * cantidad, 2)
                db.add(DetallePedido(
                    pedido_id=pedido.id,
                    variante_id=variante.id,
                    cantidad=cantidad,
                    precio_unitario=precio,
                    subtotal=subtotal,
                ))
                total += subtotal
                stats["detalles"] += 1

            pedido.total = round(total, 2)
            stats["pedidos"] += 1

            # Pago completado para pedidos con flujo de cobro.
            if estado in ("pagado", "enviado", "entregado"):
                db.add(Pago(
                    pedido_id=pedido.id,
                    empresa_id=empresa.id,
                    metodo=random.choice(METODOS_PAGO),
                    monto=round(total, 2),
                    estado="completado",
                    referencia=f"SEED-{pedido.id}",
                    fecha_pago=fecha,
                ))
                stats["pagos"] += 1

        # ------------------------------------------------------------------
        # Reservas del mes (Requieren sucursal: solo si la empresa tiene)
        # ------------------------------------------------------------------
        if sucursales:
            cantidad_reservas = random.randint(*RESERVAS_POR_MES)
            for _ in range(cantidad_reservas):
                fecha = _fecha_aleatoria_en_mes(hoy, meses_atras)
                cliente = random.choice(clientes)
                estado_reserva = random.choices(
                    [e for e, _ in ESTADOS_RESERVA],
                    weights=[w for _, w in ESTADOS_RESERVA],
                )[0]
                db.add(Reserva(
                    usuario_id=cliente.id,
                    sucursal_id=random.choice(sucursales).id,
                    empresa_id=empresa.id,
                    fecha_reserva=fecha,
                    estado=estado_reserva,
                    observaciones="Reserva generada por seed de prueba",
                ))
                stats["reservas"] += 1

    db.commit()
    return stats


def seed_datos_prueba() -> int:
    db = SessionLocal()
    try:
        hoy = datetime.now()

        empresas = db.query(Empresa).filter(Empresa.activo == True).all()  # noqa: E712
        if not empresas:
            print("ERROR: no hay empresas activas en la base de datos.")
            return 1
        print("Empresas destino:")
        for e in empresas:
            print(f"  - [{e.id}] {e.nombre}")

        borrados = limpiar_seed_anterior(db)
        if borrados:
            print(f"\nLimpieza de seed anterior: {borrados} clientes seed eliminados con sus datos.")

        print(f"\nGenerando datos de los últimos {MESES_HISTORIAL} meses...")
        id_principal = min(e.id for e in empresas)
        resultados = []
        for empresa in empresas:
            print(f"\n>>> Empresa: {empresa.nombre} (id={empresa.id})")
            stats = _poblar_empresa(db, empresa, hoy, es_principal=(empresa.id == id_principal))
            resultados.append(stats)
            if stats["omitida"]:
                print(f"    OMITIDA: {stats['motivo']}")
            else:
                print(
                    f"    OK: {stats['pedidos']} pedidos · {stats['detalles']} detalles · "
                    f"{stats['pagos']} pagos · {stats['reservas']} reservas · "
                    f"{stats['clientes']} clientes seed"
                )

        print("\n================ RESUMEN seed_datos_prueba ================")
        for r in resultados:
            if r["omitida"]:
                print(f"  {r['empresa']}: OMITIDA ({r['motivo']})")
            else:
                print(
                    f"  {r['empresa']}: {r['pedidos']} pedidos · "
                    f"{r['pagos']} pagos · {r['reservas']} reservas · "
                    f"{r['clientes']} clientes seed"
                )
        print("Listo. Los gráficos del Dashboard ya tienen datos históricos.")
        return 0
    except Exception as e:
        db.rollback()
        print(f"ERROR: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    raise SystemExit(seed_datos_prueba())
