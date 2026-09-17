from typing import List

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.branch import Sucursal
from app.schemas.branch import SucursalCrear, SucursalActualizar


def listar_sucursales(db: Session, solo_activos: bool = True) -> List[Sucursal]:
    query = db.query(Sucursal)

    if solo_activos:
        query = query.filter(Sucursal.activo.is_(True))

    return query.order_by(Sucursal.nombre).all()


def obtener_sucursal_por_id(db: Session, sucursal_id: int) -> Sucursal:
    sucursal = db.query(Sucursal).filter(Sucursal.id == sucursal_id).first()

    if not sucursal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sucursal no encontrada"
        )
    return sucursal


def crear_sucursal(db: Session, datos: SucursalCrear) -> Sucursal:
    existente = db.query(Sucursal).filter(
        Sucursal.nombre == datos.nombre
    ).first()

    if existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe una sucursal con ese nombre"
        )

    nueva_sucursal = Sucursal(
        nombre=datos.nombre,
        direccion=datos.direccion,
        ciudad=datos.ciudad,
        telefono=datos.telefono,
        activo=True
    )

    db.add(nueva_sucursal)
    db.commit()
    db.refresh(nueva_sucursal)

    return nueva_sucursal


def actualizar_sucursal(
    db: Session,
    sucursal_id: int,
    datos: SucursalActualizar
) -> Sucursal:
    sucursal = obtener_sucursal_por_id(db, sucursal_id)

    datos_actualizar = datos.model_dump(exclude_unset=True)
    for campo, valor in datos_actualizar.items():
        setattr(sucursal, campo, valor)

    db.commit()
    db.refresh(sucursal)

    return sucursal


def eliminar_sucursal(db: Session, sucursal_id: int) -> Sucursal:
    sucursal = obtener_sucursal_por_id(db, sucursal_id)
    sucursal.activo = False

    db.commit()
    db.refresh(sucursal)

    return sucursal
