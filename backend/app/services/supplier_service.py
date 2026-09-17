from typing import List

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.supplier import Proveedor
from app.schemas.supplier import ProveedorCrear, ProveedorActualizar


def listar_proveedores(db: Session, solo_activos: bool = True) -> List[Proveedor]:
    query = db.query(Proveedor)

    if solo_activos:
        query = query.filter(Proveedor.activo.is_(True))

    return query.order_by(Proveedor.nombre).all()


def obtener_proveedor_por_id(db: Session, proveedor_id: int) -> Proveedor:
    proveedor = db.query(Proveedor).filter(Proveedor.id == proveedor_id).first()

    if not proveedor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Proveedor no encontrado"
        )
    return proveedor


def crear_proveedor(db: Session, datos: ProveedorCrear) -> Proveedor:
    nuevo_proveedor = Proveedor(
        nombre=datos.nombre,
        contacto=datos.contacto,
        telefono=datos.telefono,
        email=datos.email,
        direccion=datos.direccion,
        activo=True
    )

    db.add(nuevo_proveedor)
    db.commit()
    db.refresh(nuevo_proveedor)

    return nuevo_proveedor


def actualizar_proveedor(
    db: Session,
    proveedor_id: int,
    datos: ProveedorActualizar
) -> Proveedor:
    proveedor = obtener_proveedor_por_id(db, proveedor_id)

    datos_actualizar = datos.model_dump(exclude_unset=True)
    for campo, valor in datos_actualizar.items():
        setattr(proveedor, campo, valor)

    db.commit()
    db.refresh(proveedor)

    return proveedor


def eliminar_proveedor(db: Session, proveedor_id: int) -> Proveedor:
    proveedor = obtener_proveedor_por_id(db, proveedor_id)
    proveedor.activo = False

    db.commit()
    db.refresh(proveedor)

    return proveedor
