from typing import List

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.season import Temporada
from app.schemas.season import TemporadaCrear, TemporadaActualizar


def listar_temporadas(db: Session, solo_activos: bool = True) -> List[Temporada]:
    query = db.query(Temporada)

    if solo_activos:
        query = query.filter(Temporada.activo.is_(True))

    return query.order_by(Temporada.nombre).all()


def obtener_temporada_por_id(db: Session, temporada_id: int) -> Temporada:
    temporada = db.query(Temporada).filter(Temporada.id == temporada_id).first()

    if not temporada:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Temporada no encontrada"
        )
    return temporada


def crear_temporada(db: Session, datos: TemporadaCrear) -> Temporada:
    existente = db.query(Temporada).filter(
        Temporada.nombre == datos.nombre
    ).first()

    if existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe una temporada con ese nombre"
        )

    nueva_temporada = Temporada(
        nombre=datos.nombre,
        descripcion=datos.descripcion,
        activo=True
    )

    db.add(nueva_temporada)
    db.commit()
    db.refresh(nueva_temporada)

    return nueva_temporada


def actualizar_temporada(
    db: Session,
    temporada_id: int,
    datos: TemporadaActualizar
) -> Temporada:
    temporada = obtener_temporada_por_id(db, temporada_id)

    datos_actualizar = datos.model_dump(exclude_unset=True)
    for campo, valor in datos_actualizar.items():
        setattr(temporada, campo, valor)

    db.commit()
    db.refresh(temporada)

    return temporada


def eliminar_temporada(db: Session, temporada_id: int) -> Temporada:
    temporada = obtener_temporada_por_id(db, temporada_id)
    temporada.activo = False

    db.commit()
    db.refresh(temporada)

    return temporada
