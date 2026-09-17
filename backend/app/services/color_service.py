from typing import List

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.color import Color
from app.schemas.color import ColorCrear, ColorActualizar


def listar_colores(db: Session, solo_activos: bool = True) -> List[Color]:
    query = db.query(Color)

    if solo_activos:
        query = query.filter(Color.activo.is_(True))

    return query.order_by(Color.id).all()


def obtener_color_por_id(db: Session, color_id: int) -> Color:
    color = db.query(Color).filter(Color.id == color_id).first()

    if not color:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Color no encontrado"
        )
    return color


def crear_color(db: Session, datos: ColorCrear) -> Color:
    existente = db.query(Color).filter(Color.nombre == datos.nombre).first()

    if existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe un color con ese nombre"
        )

    nuevo_color = Color(
        nombre=datos.nombre,
        codigo_hex=datos.codigo_hex,
        activo=True
    )

    db.add(nuevo_color)
    db.commit()
    db.refresh(nuevo_color)

    return nuevo_color


def actualizar_color(db: Session, color_id: int, datos: ColorActualizar) -> Color:
    color = obtener_color_por_id(db, color_id)

    datos_actualizar = datos.model_dump(exclude_unset=True)
    for campo, valor in datos_actualizar.items():
        setattr(color, campo, valor)

    db.commit()
    db.refresh(color)

    return color


def eliminar_color(db: Session, color_id: int) -> Color:
    color = obtener_color_por_id(db, color_id)
    color.activo = False

    db.commit()
    db.refresh(color)

    return color
