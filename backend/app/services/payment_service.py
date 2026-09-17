from datetime import datetime, timezone, timezone
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

    metodos_permitidos = payment_type_service.nombres_tipos_pago_activos(db)
    metodo_normalizado = datos.metodo.strip().lower()
    if metodo_normalizado not in metodos_permitidos:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Método de pago no válido. Permitidos: {', '.join(metodos_permitidos)}"
        )

    if round(float(datos.monto), 2) != round(float(pedido.total), 2):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"El monto del pago (${datos.monto:.2f}) no coincide exactamente con el total del pedido (${pedido.total:.2f})"
        )


    try:
        nuevo_pago = Pago(
            pedido_id=datos.pedido_id,
            metodo=datos.metodo,
            monto=round(datos.monto, 2),
            estado="aprobado",
            referencia=datos.referencia,
            fecha_pago=datetime.now(timezone.utc)
        )
        db.add(nuevo_pago)

        pedido.estado = "pagado"

        crear_notificacion(
            db,
            usuario_id=usuario_id,
            titulo="Pago Aprobado",
            mensaje=f"Se ha procesado exitosamente tu pago por ${nuevo_pago.monto:.2f} para el pedido #{pedido.id}."
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
