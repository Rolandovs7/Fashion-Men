from typing import List

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.discount import Descuento
from app.schemas.discount import DescuentoCrear, DescuentoActualizar


def listar_descuentos(db: Session, solo_activos: bool = True) -> List[Descuento]:
    query = db.query(Descuento)

    if solo_activos:
        query = query.filter(Descuento.activo.is_(True))

    return query.order_by(Descuento.id.desc()).all()


def obtener_descuento_por_id(db: Session, descuento_id: int) -> Descuento:
    descuento = db.query(Descuento).filter(Descuento.id == descuento_id).first()

    if not descuento:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Descuento no encontrado"
        )
    return descuento


def crear_descuento(db: Session, datos: DescuentoCrear) -> Descuento:
    nuevo = Descuento(
        nombre=datos.nombre,
        porcentaje=datos.porcentaje,
        fecha_inicio=datos.fecha_inicio,
        fecha_fin=datos.fecha_fin,
        activo=True
    )

    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)

    return nuevo


def actualizar_descuento(db: Session, descuento_id: int, datos: DescuentoActualizar) -> Descuento:
    descuento = obtener_descuento_por_id(db, descuento_id)

    datos_actualizar = datos.model_dump(exclude_unset=True)
    for campo, valor in datos_actualizar.items():
        setattr(descuento, campo, valor)

    db.commit()
    db.refresh(descuento)

    return descuento


def eliminar_descuento(db: Session, descuento_id: int) -> Descuento:
    descuento = obtener_descuento_por_id(db, descuento_id)
    descuento.activo = False

    db.commit()
    db.refresh(descuento)

    return descuento
