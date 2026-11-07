from datetime import datetime, timezone
from typing import List
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.payment import Pago
from app.models.order import Pedido
from app.schemas.payment import PagoCrear
from app.services.notification_service import crear_notificacion
from app.services import payment_type_service


def registrar_pago(
    db: Session,
    usuario_id: int,
    datos: PagoCrear
) -> Pago:
    # [Segundo Parcial] CU02/CU19 - Checkout tienda:
    # tarjeta = simulación de aprobación (aprobado/pagado)
    # qr/efectivo = registro pendiente (pendiente/pendiente_pago), no "Pagado"
    pedido = db.query(Pedido).filter(
        Pedido.id == datos.pedido_id,
        Pedido.usuario_id == usuario_id
    ).first()

    if not pedido:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pedido no encontrado"
        )

    if pedido.estado != "pendiente":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"No se pueden registrar pagos para un pedido en estado '{pedido.estado}'"
        )

    pago_existente = db.query(Pago).filter(
        Pago.pedido_id == datos.pedido_id,
        Pago.estado == "aprobado"
    ).first()

    if pago_existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe un pago aprobado registrado para este pedido"
        )

    metodo_normalizado = datos.metodo.strip().lower()
    metodos_simulados = {"tarjeta", "qr", "efectivo"}
    if metodo_normalizado not in metodos_simulados:
        metodos_permitidos = payment_type_service.nombres_tipos_pago_activos(db)
        if metodo_normalizado not in metodos_permitidos:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Método de pago no válido. Permitidos: {', '.join(sorted(set(metodos_permitidos) | metodos_simulados))}"
            )

    if round(float(datos.monto), 2) != round(float(pedido.total), 2):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"El monto del pago (${datos.monto:.2f}) no coincide exactamente con el total del pedido (${pedido.total:.2f})"
        )

    try:
        ahora = datetime.now(timezone.utc)
        if metodo_normalizado == "tarjeta":
            estado_pago = "aprobado"
            fecha_pago = ahora
            estado_pedido = "pagado"
            titulo_notif = "Pago Aprobado"
            mensaje_notif = f"Se ha procesado exitosamente tu pago por ${round(float(datos.monto), 2):.2f} para el pedido #{pedido.id}."
        else:
            estado_pago = "pendiente"
            fecha_pago = None
            estado_pedido = "pendiente_pago"
            etiqueta = "QR" if metodo_normalizado == "qr" else "efectivo"
            titulo_notif = "Pago pendiente"
            mensaje_notif = f"Tu pedido #{pedido.id} quedó en estado Pendiente de Pago ({etiqueta}) por ${round(float(datos.monto), 2):.2f}."

        nuevo_pago = Pago(
            pedido_id=datos.pedido_id,
            metodo=metodo_normalizado,
            monto=round(float(datos.monto), 2),
            estado=estado_pago,
            referencia=datos.referencia,
            fecha_pago=fecha_pago
        )
        db.add(nuevo_pago)

        pedido.estado = estado_pedido

        crear_notificacion(
            db,
            usuario_id=usuario_id,
            titulo=titulo_notif,
            mensaje=mensaje_notif
        )

        db.commit()
        db.refresh(nuevo_pago)

        return nuevo_pago

    except Exception:
        db.rollback()
        raise


def listar_pagos_pedido(
    db: Session,
    usuario_id: int,
    pedido_id: int
) -> List[Pago]:
    pedido = db.query(Pedido).filter(
        Pedido.id == pedido_id,
        Pedido.usuario_id == usuario_id
    ).first()

    if not pedido:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pedido no encontrado"
        )

    return db.query(Pago).filter(
        Pago.pedido_id == pedido_id
    ).order_by(Pago.fecha_pago.desc()).all()
