from datetime import datetime, timezone, timezone
from typing import List
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.return_model import Devolucion
from app.models.order import Pedido
from app.models.order_detail import DetallePedido
from app.models.inventory import Inventario
from app.models.branch import Sucursal
from app.schemas.return_schema import DevolucionSolicitar, DevolucionCambiarEstadoAdmin
from app.services.notification_service import crear_notificacion


def listar_devoluciones_usuario(
    db: Session,
    usuario_id: int
) -> List[Devolucion]:
    return db.query(Devolucion).join(
        Pedido, Devolucion.pedido_id == Pedido.id
    ).filter(
        Pedido.usuario_id == usuario_id
    ).order_by(Devolucion.fecha_devolucion.desc()).all()


def obtener_devolucion_por_id(
    db: Session,
    usuario_id: int,
    devolucion_id: int
) -> Devolucion:
    devolucion = db.query(Devolucion).join(
        Pedido, Devolucion.pedido_id == Pedido.id
    ).filter(
        Devolucion.id == devolucion_id,
        Pedido.usuario_id == usuario_id
    ).first()

    if not devolucion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Devolución no encontrada"
        )
    return devolucion


def solicitar_devolucion(
    db: Session,
    usuario_id: int,
    datos: DevolucionSolicitar
) -> Devolucion:
    pedido = db.query(Pedido).filter(
        Pedido.id == datos.pedido_id,
        Pedido.usuario_id == usuario_id
    ).first()

    if not pedido:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pedido no encontrado"
        )

    estados_elegibles = ["entregado", "pagado", "enviado"]
    if pedido.estado not in estados_elegibles:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"No se pueden solicitar devoluciones para un pedido en estado '{pedido.estado}'"
        )

    detalle_pedido = db.query(DetallePedido).filter(
        DetallePedido.pedido_id == datos.pedido_id,
        DetallePedido.variante_id == datos.variante_id
    ).first()

    if not detalle_pedido:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"La variante ID {datos.variante_id} no forma parte del pedido #{datos.pedido_id}"
        )

    if datos.cantidad <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La cantidad a devolver debe ser mayor a 0"
        )

    # Calcular devoluciones previas que no hayan sido rechazadas
    devoluciones_previas = db.query(Devolucion).filter(
        Devolucion.pedido_id == datos.pedido_id,
        Devolucion.variante_id == datos.variante_id,
        Devolucion.estado.in_(["solicitada", "aprobada", "completada"])
    ).all()

    cantidad_ya_devuelta = sum(dev.cantidad for dev in devoluciones_previas)

    if (cantidad_ya_devuelta + datos.cantidad) > detalle_pedido.cantidad:
        disponible_para_devolver = detalle_pedido.cantidad - cantidad_ya_devuelta
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"La cantidad a devolver ({datos.cantidad}) supera el máximo disponible para devolución "
                f"({disponible_para_devolver}) de la cantidad comprada ({detalle_pedido.cantidad})."
            )
        )

    try:
        nueva_devolucion = Devolucion(
            pedido_id=datos.pedido_id,
            variante_id=datos.variante_id,
            cantidad=datos.cantidad,
            motivo=datos.motivo,
            estado="solicitada",
            fecha_devolucion=datetime.now(timezone.utc)
        )
        db.add(nueva_devolucion)

        crear_notificacion(
            db,
            usuario_id=usuario_id,
            titulo="Devolución Solicitada",
            mensaje=f"Tu solicitud de devolución para la variante ID {datos.variante_id} del pedido #{pedido.id} ha sido registrada."
        )

        db.commit()
        db.refresh(nueva_devolucion)

        return nueva_devolucion

    except Exception:
        db.rollback()
        raise


def cambiar_estado_devolucion_admin(
    db: Session,
    devolucion_id: int,
    datos: DevolucionCambiarEstadoAdmin
) -> Devolucion:
    devolucion = db.query(Devolucion).filter(Devolucion.id == devolucion_id).first()

    if not devolucion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Devolución no encontrada"
        )

    nuevo_estado = datos.nuevo_estado.strip().lower()
    estados_validos = ["solicitada", "aprobada", "rechazada", "completada"]

    if nuevo_estado not in estados_validos:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Estado inválido. Estados permitidos: {', '.join(estados_validos)}"
        )

    if devolucion.estado in ["completada", "rechazada"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"La devolución #{devolucion.id} ya se encuentra en estado final '{devolucion.estado}' y no puede modificarse"
        )

    if devolucion.estado == nuevo_estado:
        return devolucion

    try:
        if nuevo_estado == "completada":
            if datos.sucursal_id:
                inventario = db.query(Inventario).filter(
                    Inventario.variante_id == devolucion.variante_id,
                    Inventario.sucursal_id == datos.sucursal_id
                ).first()

                if not inventario:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"No hay inventario registrado para la variante ID {devolucion.variante_id} en la sucursal ID {datos.sucursal_id}"
                    )
            else:
                inventarios = db.query(Inventario).join(
                    Sucursal, Inventario.sucursal_id == Sucursal.id
                ).filter(
                    Inventario.variante_id == devolucion.variante_id,
                    Sucursal.activo.is_(True)
                ).all()

                if len(inventarios) == 1:
                    inventario = inventarios[0]
                else:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Debe proporcionar 'sucursal_id' en el cuerpo para especificar en qué sucursal reponer el producto devuelto."
                    )

            inventario.cantidad += devolucion.cantidad

        devolucion.estado = nuevo_estado

        pedido = db.query(Pedido).filter(Pedido.id == devolucion.pedido_id).first()
        if pedido:
            crear_notificacion(
                db,
                usuario_id=pedido.usuario_id,
                titulo="Estado de Devolución",
                mensaje=f"El estado de tu solicitud de devolución #{devolucion.id} ha cambiado a '{nuevo_estado}'."
            )

        db.commit()
        db.refresh(devolucion)

        return devolucion

    except Exception:
        db.rollback()
        raise
