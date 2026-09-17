from typing import List

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.brand import Marca
from app.schemas.brand import MarcaCrear, MarcaActualizar


def listar_marcas(db: Session, solo_activos: bool = True) -> List[Marca]:
    query = db.query(Marca)

    if solo_activos:
        query = query.filter(Marca.activo.is_(True))

    return query.order_by(Marca.nombre).all()


def obtener_marca_por_id(db: Session, marca_id: int) -> Marca:
    marca = db.query(Marca).filter(Marca.id == marca_id).first()

    if not marca:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Marca no encontrada"
        )
    return marca


def crear_marca(db: Session, datos: MarcaCrear) -> Marca:
    existente = db.query(Marca).filter(Marca.nombre == datos.nombre).first()

    if existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe una marca con ese nombre"
        )

    nueva = Marca(nombre=datos.nombre, descripcion=datos.descripcion, activo=True)

    db.add(nueva)
    db.commit()
    db.refresh(nueva)

    return nueva


def actualizar_marca(db: Session, marca_id: int, datos: MarcaActualizar) -> Marca:
    marca = obtener_marca_por_id(db, marca_id)

    datos_actualizar = datos.model_dump(exclude_unset=True)
    for campo, valor in datos_actualizar.items():
        setattr(marca, campo, valor)

    db.commit()
    db.refresh(marca)

    return marca


def eliminar_marca(db: Session, marca_id: int) -> Marca:
    marca = obtener_marca_por_id(db, marca_id)
    marca.activo = False

    db.commit()
    db.refresh(marca)

    return marca
