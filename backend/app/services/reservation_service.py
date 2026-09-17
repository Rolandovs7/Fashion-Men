from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.reservation import Reserva
from app.models.reservation_detail import DetalleReserva
from app.models.inventory import Inventario
from app.models.product_variant import ProductoVariante
from app.models.branch import Sucursal
from app.models.user import Usuario
from app.schemas.reservation import ReservaCrear
from app.services.notification_service import crear_notificacion


def listar_reservas_usuario(
    db: Session,
    usuario_id: int,
    estado: Optional[str] = None
) -> List[Reserva]:
    query = db.query(Reserva).filter(Reserva.usuario_id == usuario_id)

    if estado:
        query = query.filter(Reserva.estado == estado.strip().lower())

    return query.order_by(Reserva.fecha_reserva.desc()).all()


def listar_todas_las_reservas(
    db: Session,
    estado: Optional[str] = None,
    sucursal_id: Optional[int] = None
) -> List[Reserva]:
    query = db.query(Reserva)

    if estado:
        query = query.filter(Reserva.estado == estado.strip().lower())

    if sucursal_id:
        query = query.filter(Reserva.sucursal_id == sucursal_id)

    return query.order_by(Reserva.fecha_reserva.desc()).all()


def obtener_reserva_por_id(
    db: Session,
    usuario_id: int,
    reserva_id: int
) -> Reserva:
    reserva = db.query(Reserva).filter(
        Reserva.id == reserva_id,
        Reserva.usuario_id == usuario_id
    ).first()

    if not reserva:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reserva no encontrada"
        )
    return reserva


def crear_reserva(
    db: Session,
    usuario_id: int,
    datos: ReservaCrear
) -> Reserva:
    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    if not usuario or not usuario.activo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El usuario no está activo o no existe"
        )

    sucursal = db.query(Sucursal).filter(Sucursal.id == datos.sucursal_id).first()
    if not sucursal or not sucursal.activo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La sucursal seleccionada no existe o está inactiva"
        )

    # Agrupar cantidades por variante_id para validar stock adecuadamente
    cantidades_por_variante = {}
    for item in datos.detalles:
        if item.cantidad <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="La cantidad debe ser mayor a 0"
            )
        cantidades_por_variante[item.variante_id] = (
            cantidades_por_variante.get(item.variante_id, 0) + item.cantidad
        )

    # Validar variantes y stock disponible en la sucursal seleccionada
    inventarios_a_actualizar = []

    for variante_id, cantidad_total in cantidades_por_variante.items():
        variante = db.query(ProductoVariante).filter(
            ProductoVariante.id == variante_id
        ).first()

        if not variante or not variante.activo:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"La variante ID {variante_id} no existe o está inactiva"
            )

        inventario = db.query(Inventario).filter(
            Inventario.variante_id == variante_id,
            Inventario.sucursal_id == datos.sucursal_id
        ).first()

        if not inventario:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"No hay inventario registrado para la variante ID {variante_id} en la sucursal seleccionada"
            )

        stock_disponible = inventario.cantidad - inventario.cantidad_reservada
        if cantidad_total > stock_disponible:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Stock insuficiente para la variante ID {variante_id}. Disponible: {stock_disponible}"
            )

        inventarios_a_actualizar.append((inventario, cantidad_total))

    try:
        nueva_reserva = Reserva(
            usuario_id=usuario_id,
            sucursal_id=datos.sucursal_id,
            fecha_reserva=datos.fecha_reserva,
            estado="pendiente",
            observaciones=datos.observaciones
        )
        db.add(nueva_reserva)
        db.flush()

        for item in datos.detalles:
            detalle = DetalleReserva(
                reserva_id=nueva_reserva.id,
                variante_id=item.variante_id,
                cantidad=item.cantidad
            )
            db.add(detalle)

        # Actualizar cantidad_reservada en el inventario
        for inventario, cantidad_total in inventarios_a_actualizar:
            inventario.cantidad_reservada += cantidad_total

        # Generar notificación
        crear_notificacion(
            db,
            usuario_id=usuario_id,
            titulo="Reserva Creada",
            mensaje=f"Tu reserva #{nueva_reserva.id} ha sido registrada con éxito en estado pendiente."
        )

        db.commit()
        db.refresh(nueva_reserva)

        return nueva_reserva

    except Exception:
        db.rollback()
        raise


def cancelar_reserva_cliente(
    db: Session,
    usuario_id: int,
    reserva_id: int
) -> Reserva:
    reserva = obtener_reserva_por_id(db, usuario_id, reserva_id)

    if reserva.estado in ["cancelada", "completada"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"La reserva ya se encuentra en estado '{reserva.estado}' y no se puede cancelar"
        )

    try:
        # Liberar stock reservado
        for detalle in reserva.detalles:
            inventario = db.query(Inventario).filter(
                Inventario.variante_id == detalle.variante_id,
                Inventario.sucursal_id == reserva.sucursal_id
            ).first()

            if inventario:
                inventario.cantidad_reservada = max(
                    0,
                    inventario.cantidad_reservada - detalle.cantidad
                )

        reserva.estado = "cancelada"

        crear_notificacion(
            db,
            usuario_id=usuario_id,
            titulo="Reserva Cancelada",
            mensaje=f"Tu reserva #{reserva.id} ha sido cancelada correctamente."
        )

        db.commit()
        db.refresh(reserva)

        return reserva

    except Exception:
        db.rollback()
        raise


def cambiar_estado_reserva_admin(
    db: Session,
    reserva_id: int,
    nuevo_estado: str
) -> Reserva:
    reserva = db.query(Reserva).filter(Reserva.id == reserva_id).first()

    if not reserva:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reserva no encontrada"
        )

    nuevo_estado_normalizado = nuevo_estado.strip().lower()
    estados_validos = ["pendiente", "confirmada", "cancelada", "completada"]

    if nuevo_estado_normalizado not in estados_validos:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Estado inválido. Estados permitidos: {', '.join(estados_validos)}"
        )

    if reserva.estado == "completada":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La reserva ya ha sido completada y no puede cambiar de estado nuevamente"
        )

    if reserva.estado == "cancelada":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La reserva ya ha sido cancelada y no puede cambiar de estado nuevamente"
        )

    if reserva.estado == nuevo_estado_normalizado:
        return reserva

    try:
        if nuevo_estado_normalizado == "confirmada":
            reserva.estado = "confirmada"
            crear_notificacion(
                db,
                usuario_id=reserva.usuario_id,
                titulo="Reserva Confirmada",
                mensaje=f"Tu reserva #{reserva.id} ha sido confirmada por la sucursal."
            )

        elif nuevo_estado_normalizado == "cancelada":
            for detalle in reserva.detalles:
                inventario = db.query(Inventario).filter(
                    Inventario.variante_id == detalle.variante_id,
                    Inventario.sucursal_id == reserva.sucursal_id
                ).first()

                if inventario:
                    inventario.cantidad_reservada = max(
                        0,
                        inventario.cantidad_reservada - detalle.cantidad
                    )

            reserva.estado = "cancelada"
            crear_notificacion(
                db,
                usuario_id=reserva.usuario_id,
                titulo="Reserva Cancelada",
                mensaje=f"Tu reserva #{reserva.id} ha sido cancelada por la administración."
            )

        elif nuevo_estado_normalizado == "completada":
            for detalle in reserva.detalles:
                inventario = db.query(Inventario).filter(
                    Inventario.variante_id == detalle.variante_id,
                    Inventario.sucursal_id == reserva.sucursal_id
                ).first()

                if inventario:
                    inventario.cantidad = max(
                        0,
                        inventario.cantidad - detalle.cantidad
                    )
                    inventario.cantidad_reservada = max(
                        0,
                        inventario.cantidad_reservada - detalle.cantidad
                    )

            reserva.estado = "completada"
            crear_notificacion(
                db,
                usuario_id=reserva.usuario_id,
                titulo="Reserva Completada",
                mensaje=f"Tu reserva #{reserva.id} ha sido completada. ¡Gracias por tu compra!"
            )

        db.commit()
        db.refresh(reserva)

        return reserva

    except Exception:
        db.rollback()
        raise
