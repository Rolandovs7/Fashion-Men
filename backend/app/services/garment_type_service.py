from typing import List

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.garment_type import TipoPrenda
from app.schemas.garment_type import TipoPrendaCrear, TipoPrendaActualizar


def listar_tipos_prenda(db: Session, solo_activos: bool = True) -> List[TipoPrenda]:
    query = db.query(TipoPrenda)

    if solo_activos:
        query = query.filter(TipoPrenda.activo.is_(True))

    return query.order_by(TipoPrenda.nombre).all()


def obtener_tipo_prenda_por_id(db: Session, tipo_prenda_id: int) -> TipoPrenda:
    tipo = db.query(TipoPrenda).filter(TipoPrenda.id == tipo_prenda_id).first()

    if not tipo:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tipo de prenda no encontrado"
        )
    return tipo


def crear_tipo_prenda(db: Session, datos: TipoPrendaCrear) -> TipoPrenda:
    existente = db.query(TipoPrenda).filter(TipoPrenda.nombre == datos.nombre).first()

    if existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe un tipo de prenda con ese nombre"
        )

    nuevo = TipoPrenda(nombre=datos.nombre, descripcion=datos.descripcion, activo=True)

    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)

    return nuevo


def actualizar_tipo_prenda(db: Session, tipo_prenda_id: int, datos: TipoPrendaActualizar) -> TipoPrenda:
    tipo = obtener_tipo_prenda_por_id(db, tipo_prenda_id)

    datos_actualizar = datos.model_dump(exclude_unset=True)
    for campo, valor in datos_actualizar.items():
        setattr(tipo, campo, valor)

    db.commit()
    db.refresh(tipo)

    return tipo


def eliminar_tipo_prenda(db: Session, tipo_prenda_id: int) -> TipoPrenda:
    tipo = obtener_tipo_prenda_por_id(db, tipo_prenda_id)
    tipo.activo = False

    db.commit()
    db.refresh(tipo)

    return tipo
