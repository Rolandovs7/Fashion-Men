from typing import List

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.payment_type import TipoPago
from app.schemas.payment_type import TipoPagoCrear, TipoPagoActualizar


def listar_tipos_pago(db: Session, solo_activos: bool = True) -> List[TipoPago]:
    query = db.query(TipoPago)

    if solo_activos:
        query = query.filter(TipoPago.activo.is_(True))

    return query.order_by(TipoPago.nombre).all()


def obtener_tipo_pago_por_id(db: Session, tipo_pago_id: int) -> TipoPago:
    tipo_pago = db.query(TipoPago).filter(TipoPago.id == tipo_pago_id).first()

    if not tipo_pago:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tipo de pago no encontrado"
        )
    return tipo_pago


def nombres_tipos_pago_activos(db: Session) -> List[str]:
    tipos = listar_tipos_pago(db, solo_activos=True)
    return [t.nombre for t in tipos]


def crear_tipo_pago(db: Session, datos: TipoPagoCrear) -> TipoPago:
    existente = db.query(TipoPago).filter(TipoPago.nombre == datos.nombre).first()

    if existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe un tipo de pago con ese nombre"
        )

    nuevo_tipo = TipoPago(nombre=datos.nombre, activo=True)

    db.add(nuevo_tipo)
    db.commit()
    db.refresh(nuevo_tipo)

    return nuevo_tipo


def actualizar_tipo_pago(db: Session, tipo_pago_id: int, datos: TipoPagoActualizar) -> TipoPago:
    tipo_pago = obtener_tipo_pago_por_id(db, tipo_pago_id)

    datos_actualizar = datos.model_dump(exclude_unset=True)
    for campo, valor in datos_actualizar.items():
        setattr(tipo_pago, campo, valor)

    db.commit()
    db.refresh(tipo_pago)

    return tipo_pago


def eliminar_tipo_pago(db: Session, tipo_pago_id: int) -> TipoPago:
    tipo_pago = obtener_tipo_pago_por_id(db, tipo_pago_id)
    tipo_pago.activo = False

    db.commit()
    db.refresh(tipo_pago)

    return tipo_pago
