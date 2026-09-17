from typing import List

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.role import Rol
from app.schemas.role import RolCrear, RolActualizar


def listar_roles(db: Session, solo_activos: bool = True) -> List[Rol]:
    query = db.query(Rol)

    if solo_activos:
        query = query.filter(Rol.activo.is_(True))

    return query.order_by(Rol.nombre).all()


def obtener_rol_por_id(db: Session, rol_id: int) -> Rol:
    rol = db.query(Rol).filter(Rol.id == rol_id).first()

    if not rol:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Rol no encontrado"
        )
    return rol


def nombres_roles_activos(db: Session) -> List[str]:
    roles = listar_roles(db, solo_activos=True)
    return [r.nombre for r in roles]


def crear_rol(db: Session, datos: RolCrear) -> Rol:
    existente = db.query(Rol).filter(Rol.nombre == datos.nombre).first()

    if existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe un rol con ese nombre"
        )

    nuevo_rol = Rol(
        nombre=datos.nombre,
        descripcion=datos.descripcion,
        activo=True
    )

    db.add(nuevo_rol)
    db.commit()
    db.refresh(nuevo_rol)

    return nuevo_rol


def actualizar_rol(db: Session, rol_id: int, datos: RolActualizar) -> Rol:
    rol = obtener_rol_por_id(db, rol_id)

    datos_actualizar = datos.model_dump(exclude_unset=True)
    for campo, valor in datos_actualizar.items():
        setattr(rol, campo, valor)

    db.commit()
    db.refresh(rol)

    return rol


def eliminar_rol(db: Session, rol_id: int) -> Rol:
    rol = obtener_rol_por_id(db, rol_id)

    if rol.nombre in ("cliente", "administrador"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se pueden desactivar los roles base del sistema"
        )

    rol.activo = False

    db.commit()
    db.refresh(rol)

    return rol
