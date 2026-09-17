from typing import List

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.size import Talla
from app.schemas.size import TallaCrear, TallaActualizar


def listar_tallas(db: Session, solo_activos: bool = True) -> List[Talla]:
    query = db.query(Talla)

    if solo_activos:
        query = query.filter(Talla.activo.is_(True))

    return query.order_by(Talla.id).all()


def obtener_talla_por_id(db: Session, talla_id: int) -> Talla:
    talla = db.query(Talla).filter(Talla.id == talla_id).first()

    if not talla:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Talla no encontrada"
        )
    return talla


def crear_talla(db: Session, datos: TallaCrear) -> Talla:
    existente = db.query(Talla).filter(Talla.nombre == datos.nombre).first()

    if existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe una talla con ese nombre"
        )

    nueva_talla = Talla(nombre=datos.nombre, activo=True)

    db.add(nueva_talla)
    db.commit()
    db.refresh(nueva_talla)

    return nueva_talla


def actualizar_talla(db: Session, talla_id: int, datos: TallaActualizar) -> Talla:
    talla = obtener_talla_por_id(db, talla_id)

    datos_actualizar = datos.model_dump(exclude_unset=True)
    for campo, valor in datos_actualizar.items():
        setattr(talla, campo, valor)

    db.commit()
    db.refresh(talla)

    return talla


def eliminar_talla(db: Session, talla_id: int) -> Talla:
    talla = obtener_talla_por_id(db, talla_id)
    talla.activo = False

    db.commit()
    db.refresh(talla)

    return talla
