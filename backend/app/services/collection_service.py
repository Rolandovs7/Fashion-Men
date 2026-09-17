from typing import List

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.collection import Coleccion
from app.schemas.collection import ColeccionCrear, ColeccionActualizar


def listar_colecciones(db: Session, solo_activos: bool = True) -> List[Coleccion]:
    query = db.query(Coleccion)

    if solo_activos:
        query = query.filter(Coleccion.activo.is_(True))

    return query.order_by(Coleccion.nombre).all()


def obtener_coleccion_por_id(db: Session, coleccion_id: int) -> Coleccion:
    coleccion = db.query(Coleccion).filter(Coleccion.id == coleccion_id).first()

    if not coleccion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Colección no encontrada"
        )
    return coleccion


def crear_coleccion(db: Session, datos: ColeccionCrear) -> Coleccion:
    existente = db.query(Coleccion).filter(
        Coleccion.nombre == datos.nombre
    ).first()

    if existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe una colección con ese nombre"
        )

    nueva_coleccion = Coleccion(
        nombre=datos.nombre,
        descripcion=datos.descripcion,
        activo=True
    )

    db.add(nueva_coleccion)
    db.commit()
    db.refresh(nueva_coleccion)

    return nueva_coleccion


def actualizar_coleccion(
    db: Session,
    coleccion_id: int,
    datos: ColeccionActualizar
) -> Coleccion:
    coleccion = obtener_coleccion_por_id(db, coleccion_id)

    datos_actualizar = datos.model_dump(exclude_unset=True)
    for campo, valor in datos_actualizar.items():
        setattr(coleccion, campo, valor)

    db.commit()
    db.refresh(coleccion)

    return coleccion


def eliminar_coleccion(db: Session, coleccion_id: int) -> Coleccion:
    coleccion = obtener_coleccion_por_id(db, coleccion_id)
    coleccion.activo = False

    db.commit()
    db.refresh(coleccion)

    return coleccion
