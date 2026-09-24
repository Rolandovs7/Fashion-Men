from datetime import datetime, timezone
from decimal import Decimal
from typing import List, Optional, TypedDict

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.order import Pedido
from app.models.order_detail import DetallePedido
from app.models.cart import Carrito
from app.models.cart_detail import DetalleCarrito
from app.models.inventory import Inventario
from app.models.product_variant import ProductoVariante
from app.models.product import Producto
from app.models.branch import Sucursal
from app.models.user import Usuario
from app.models.payment import Pago
from app.schemas.order import PedidoCrear, PedidoCambiarEstadoAdmin, VentaPresencialCrear
from app.services.notification_service import crear_notificacion
from app.services import payment_type_service


class ItemPedidoProcesar(TypedDict):
    variante_id: int
    cantidad: int
    precio_unitario: Decimal
    subtotal: Decimal
    inventario: Inventario


def listar_pedidos_usuario(
    db: Session,
    usuario_id: int,
    estado: Optional[str] = None
) -> List[Pedido]:
    query = db.query(Pedido).filter(
        Pedido.usuario_id == usuario_id
    )

    if estado:
        query = query.filter(
            Pedido.estado == estado.strip().lower()
        )

    return query.order_by(
        Pedido.fecha_pedido.desc()
    ).all()


def listar_todos_los_pedidos(
    db: Session,
    estado: Optional[str] = None
) -> List[Pedido]:
    query = db.query(Pedido)

    if estado:
        query = query.filter(
            Pedido.estado == estado.strip().lower()
        )

    return query.order_by(
        Pedido.fecha_pedido.desc()
    ).all()


def obtener_pedido_por_id(
    db: Session,
    usuario_id: int,
    pedido_id: int
) -> Pedido:
    pedido = db.query(Pedido).filter(
        Pedido.id == pedido_id,
        Pedido.usuario_id == usuario_id
    ).first()

    if not pedido:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pedido no encontrado"
        )

    return pedido


def crear_pedido_desde_carrito(
    db: Session,
    usuario_id: int,
    datos: PedidoCrear
) -> Pedido:
    sucursal = db.query(Sucursal).filter(
        Sucursal.id == datos.sucursal_id
    ).first()

    if not sucursal or not sucursal.activo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La sucursal especificada no existe o está inactiva"
        )

    carrito = db.query(Carrito).filter(
        Carrito.usuario_id == usuario_id
    ).first()

    if not carrito or not carrito.detalles:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El carrito de compras está vacío"
        )

    detalles_carrito = list(carrito.detalles)

    items_a_procesar: List[ItemPedidoProcesar] = []

    # Los valores monetarios se manejan como Decimal.
    total_pedido = Decimal("0.00")

    for item in detalles_carrito:

        if item.cantidad <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="La cantidad de un ítem en el carrito debe ser mayor a 0"
            )

        variante = db.query(ProductoVariante).filter(
            ProductoVariante.id == item.variante_id
        ).first()

        if not variante or not variante.activo:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"La variante ID {item.variante_id} "
                    "no existe o está inactiva"
                )
            )

        producto = db.query(Producto).filter(
            Producto.id == variante.producto_id
        ).first()

        if not producto or not producto.activo:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"El producto asociado a la variante "
                    f"ID {item.variante_id} no está activo"
                )
            )

        inventario = db.query(Inventario).filter(
            Inventario.variante_id == item.variante_id,
            Inventario.sucursal_id == datos.sucursal_id
        ).first()

        if not inventario:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"No hay inventario registrado para la variante "
                    f"ID {item.variante_id} en la sucursal seleccionada"
                )
            )

        stock_disponible = (
            inventario.cantidad -
            inventario.cantidad_reservada
        )

        if item.cantidad > stock_disponible:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Stock insuficiente para la variante "
                    f"ID {item.variante_id}. "
                    f"Disponible: {stock_disponible}"
                )
            )

        # Numeric de SQLAlchemy devuelve Decimal.
        precio_unitario: Decimal = producto.precio

        subtotal = (
            precio_unitario * item.cantidad
        ).quantize(Decimal("0.01"))

        total_pedido += subtotal

        items_a_procesar.append({
            "variante_id": item.variante_id,
            "cantidad": item.cantidad,
            "precio_unitario": precio_unitario,
            "subtotal": subtotal,
            "inventario": inventario
        })

    try:
        nuevo_pedido = Pedido(
            usuario_id=usuario_id,
            sucursal_id=datos.sucursal_id,
            fecha_pedido=datetime.now(timezone.utc),
            estado="pendiente",
            total=total_pedido.quantize(Decimal("0.01"))
        )

        db.add(nuevo_pedido)
        db.flush()

        for item_data in items_a_procesar:

            detalle_pedido = DetallePedido(
                pedido_id=nuevo_pedido.id,
                variante_id=item_data["variante_id"],
                cantidad=item_data["cantidad"],
                precio_unitario=item_data["precio_unitario"],
                subtotal=item_data["subtotal"]
            )

            db.add(detalle_pedido)

            # Descontar stock físico de la sucursal seleccionada.
            inventario: Inventario = item_data["inventario"]
            cantidad: int = item_data["cantidad"]

            inventario.cantidad -= cantidad

        # Vaciar el carrito del usuario.
        db.query(DetalleCarrito).filter(
            DetalleCarrito.carrito_id == carrito.id
        ).delete(
            synchronize_session=False
        )

        # Generar notificación.
        crear_notificacion(
            db,
            usuario_id=usuario_id,
            titulo="Pedido Creado",
            mensaje=(
                f"Tu pedido #{nuevo_pedido.id} ha sido registrado "
                f"exitosamente por un total de "
                f"${nuevo_pedido.total:.2f}."
            )
        )

        db.commit()
        db.refresh(nuevo_pedido)

        return nuevo_pedido

    except Exception:
        db.rollback()
        raise


def cancelar_pedido_cliente(
    db: Session,
    usuario_id: int,
    pedido_id: int
) -> Pedido:
    pedido = obtener_pedido_por_id(
        db,
        usuario_id,
        pedido_id
    )

    estados_permitidos = [
        "pendiente",
        "pagado",
        "procesando"
    ]

    if pedido.estado not in estados_permitidos:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"No se puede cancelar el pedido #{pedido.id} "
                f"porque su estado actual es '{pedido.estado}'"
            )
        )

    # Identificar inventarios para la reposición de stock de forma segura.
    # Si el pedido tiene sucursal_id (emitido en la creación), se repone el
    # stock SOLO en esa sucursal. Pedidos viejos sin sucursal_id usan la
    # lógica anterior (requieren una única sucursal activa por variante).
    inventarios_a_reponer: list[tuple[Inventario, int]] = []

    for detalle in pedido.detalles:

        if pedido.sucursal_id:

            inventario = db.query(Inventario).filter(
                Inventario.variante_id == detalle.variante_id,
                Inventario.sucursal_id == pedido.sucursal_id
            ).first()

            if not inventario:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=(
                        f"No existe inventario registrado para la variante "
                        f"ID {detalle.variante_id} en la sucursal "
                        f"del pedido #{pedido.id}."
                    )
                )

            inventarios_a_reponer.append(
                (
                    inventario,
                    detalle.cantidad
                )
            )

            continue

        inventarios_variante = db.query(Inventario).join(
            Sucursal,
            Inventario.sucursal_id == Sucursal.id
        ).filter(
            Inventario.variante_id == detalle.variante_id,
            Sucursal.activo.is_(True)
        ).all()

        if len(inventarios_variante) == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    "No existe inventario registrado en ninguna "
                    "sucursal activa para la variante "
                    f"ID {detalle.variante_id}"
                )
            )

        if len(inventarios_variante) > 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"No se puede reponer el stock automáticamente "
                    f"al cancelar el pedido #{pedido.id} porque la "
                    f"variante ID {detalle.variante_id} está presente "
                    "en múltiples sucursales activas. Solicite la "
                    "cancelación a un administrador para que indique "
                    "la sucursal de destino."
                )
            )

        inventarios_a_reponer.append(
            (
                inventarios_variante[0],
                detalle.cantidad
            )
        )

    try:
        for inventario, cantidad in inventarios_a_reponer:
            inventario.cantidad += cantidad

        pedido.estado = "cancelado"

        crear_notificacion(
            db,
            usuario_id=usuario_id,
            titulo="Pedido Cancelado",
            mensaje=(
                f"Tu pedido #{pedido.id} ha sido cancelado "
                "y el inventario ha sido reabastecido."
            )
        )

        db.commit()
        db.refresh(pedido)

        return pedido

    except Exception:
        db.rollback()
        raise


def cambiar_estado_pedido_admin(
    db: Session,
    pedido_id: int,
    datos: PedidoCambiarEstadoAdmin
) -> Pedido:
    pedido = db.query(Pedido).filter(
        Pedido.id == pedido_id
    ).first()

    if not pedido:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pedido no encontrado"
        )

    nuevo_estado = datos.nuevo_estado.strip().lower()

    estados_validos = [
        "pendiente",
        "pagado",
        "procesando",
        "enviado",
        "entregado",
        "cancelado"
    ]

    if nuevo_estado not in estados_validos:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Estado inválido. Estados permitidos: "
                f"{', '.join(estados_validos)}"
            )
        )

    if pedido.estado in ["cancelado", "entregado"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"El pedido #{pedido.id} ya se encuentra en "
                f"estado final '{pedido.estado}' y no puede "
                "cambiar de estado"
            )
        )

    if pedido.estado == nuevo_estado:
        return pedido

    try:

        if nuevo_estado == "cancelado":

            for detalle in pedido.detalles:

                if datos.sucursal_id:

                    inventario = db.query(Inventario).filter(
                        Inventario.variante_id == detalle.variante_id,
                        Inventario.sucursal_id == datos.sucursal_id
                    ).first()

                else:

                    inventarios = db.query(Inventario).join(
                        Sucursal,
                        Inventario.sucursal_id == Sucursal.id
                    ).filter(
                        Inventario.variante_id == detalle.variante_id,
                        Sucursal.activo.is_(True)
                    ).all()

                    if len(inventarios) == 1:
                        inventario = inventarios[0]

                    else:
                        raise HTTPException(
                            status_code=status.HTTP_400_BAD_REQUEST,
                            detail=(
                                f"La variante ID {detalle.variante_id} "
                                "se encuentra en múltiples sucursales. "
                                "Debe proporcionar 'sucursal_id' para "
                                "especificar dónde reponer el stock."
                            )
                        )

                if inventario:
                    inventario.cantidad += detalle.cantidad

        pedido.estado = nuevo_estado

        crear_notificacion(
            db,
            usuario_id=pedido.usuario_id,
            titulo="Actualización de Pedido",
            mensaje=(
                f"El estado de tu pedido #{pedido.id} "
                f"ha cambiado a '{nuevo_estado}'."
            )
        )

        db.commit()
        db.refresh(pedido)

        return pedido

    except Exception:
        db.rollback()
        raise

def crear_venta_presencial(
    db: Session,
    datos: VentaPresencialCrear
) -> Pedido:
    """
    Registra una venta presencial (punto de caja): un administrador/cajero
    genera un pedido a nombre de un cliente ya existente, descuenta el
    inventario de la sucursal y registra el pago como aprobado de inmediato.
    Cubre RF17 (venta presencial) y RF18 (pago en punto de caja).
    """

    cliente = db.query(Usuario).filter(
        Usuario.id == datos.usuario_id
    ).first()

    if not cliente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El cliente especificado no existe"
        )

    sucursal = db.query(Sucursal).filter(
        Sucursal.id == datos.sucursal_id
    ).first()

    if not sucursal or not sucursal.activo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La sucursal especificada no existe o está inactiva"
        )

    metodos_permitidos = payment_type_service.nombres_tipos_pago_activos(db)
    metodo_normalizado = datos.metodo_pago.strip().lower()
    if metodo_normalizado not in metodos_permitidos:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Método de pago no válido. Permitidos: {', '.join(metodos_permitidos)}"
        )

    items_a_procesar: List[ItemPedidoProcesar] = []
    total_pedido = Decimal("0.00")

    for item in datos.items:

        variante = db.query(ProductoVariante).filter(
            ProductoVariante.id == item.variante_id
        ).first()

        if not variante or not variante.activo:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"La variante ID {item.variante_id} no existe o está inactiva"
            )

        producto = db.query(Producto).filter(
            Producto.id == variante.producto_id
        ).first()

        if not producto or not producto.activo:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"El producto asociado a la variante "
                    f"ID {item.variante_id} no está activo"
                )
            )

        inventario = db.query(Inventario).filter(
            Inventario.variante_id == item.variante_id,
            Inventario.sucursal_id == datos.sucursal_id
        ).first()

        if not inventario:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"No hay inventario registrado para la variante "
                    f"ID {item.variante_id} en la sucursal seleccionada"
                )
            )

        stock_disponible = inventario.cantidad - inventario.cantidad_reservada

        if item.cantidad > stock_disponible:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Stock insuficiente para la variante ID {item.variante_id}. "
                    f"Disponible: {stock_disponible}"
                )
            )

        precio_unitario: Decimal = producto.precio
        subtotal = (precio_unitario * item.cantidad).quantize(Decimal("0.01"))
        total_pedido += subtotal

        items_a_procesar.append({
            "variante_id": item.variante_id,
            "cantidad": item.cantidad,
            "precio_unitario": precio_unitario,
            "subtotal": subtotal,
            "inventario": inventario
        })

    try:
        nuevo_pedido = Pedido(
            usuario_id=datos.usuario_id,
            sucursal_id=datos.sucursal_id,
            fecha_pedido=datetime.now(timezone.utc),
            estado="pagado",
            total=total_pedido.quantize(Decimal("0.01"))
        )

        db.add(nuevo_pedido)
        db.flush()

        for item_data in items_a_procesar:
            detalle_pedido = DetallePedido(
                pedido_id=nuevo_pedido.id,
                variante_id=item_data["variante_id"],
                cantidad=item_data["cantidad"],
                precio_unitario=item_data["precio_unitario"],
                subtotal=item_data["subtotal"]
            )
            db.add(detalle_pedido)

            inventario: Inventario = item_data["inventario"]
            inventario.cantidad -= item_data["cantidad"]

        nuevo_pago = Pago(
            pedido_id=nuevo_pedido.id,
            metodo=metodo_normalizado,
            monto=total_pedido.quantize(Decimal("0.01")),
            estado="aprobado",
            referencia="Venta presencial en punto de caja",
            fecha_pago=datetime.now(timezone.utc)
        )
        db.add(nuevo_pago)

        crear_notificacion(
            db,
            usuario_id=datos.usuario_id,
            titulo="Compra registrada en tienda",
            mensaje=(
                f"Se registró tu compra #{nuevo_pedido.id} por "
                f"${nuevo_pedido.total:.2f} en {sucursal.nombre}."
            )
        )

        db.commit()
        db.refresh(nuevo_pedido)

        return nuevo_pedido

    except Exception:
        db.rollback()
        raise
