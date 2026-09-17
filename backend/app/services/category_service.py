from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.category import Categoria
from app.schemas.category import CategoriaCrear, CategoriaActualizar


def listar_categorias(
    db: Session,
    solo_activos: bool = False
) -> List[Categoria]:
    query = db.query(Categoria)
    if solo_activos:
        query = query.filter(Categoria.activo.is_(True))
    return query.all()


def obtener_categoria_por_id(
    db: Session,
    categoria_id: int
) -> Categoria:
    categoria = db.query(Categoria).filter(
        Categoria.id == categoria_id
    ).first()

    if not categoria:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Categoría no encontrada"
        )
    return categoria


def crear_categoria(
    db: Session,
    datos: CategoriaCrear
) -> Categoria:
    nombre_limpio = datos.nombre.strip()
    if not nombre_limpio:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El nombre de la categoría es obligatorio"
        )

    existente = db.query(Categoria).filter(
        Categoria.nombre.ilike(nombre_limpio)
    ).first()

    if existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe una categoría con este nombre"
        )

    nueva_categoria = Categoria(
        nombre=nombre_limpio,
        descripcion=datos.descripcion,
        activo=True
    )

    db.add(nueva_categoria)
    db.commit()
    db.refresh(nueva_categoria)

    return nueva_categoria


def actualizar_categoria(
    db: Session,
    categoria_id: int,
    datos: CategoriaActualizar
) -> Categoria:
    categoria = obtener_categoria_por_id(db, categoria_id)

    if datos.nombre is not None:
        nombre_limpio = datos.nombre.strip()
        if not nombre_limpio:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El nombre de la categoría no puede estar vacío"
            )

        duplicado = db.query(Categoria).filter(
            Categoria.nombre.ilike(nombre_limpio),
            Categoria.id != categoria_id
        ).first()

        if duplicado:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Ya existe una categoría con este nombre"
            )

        categoria.nombre = nombre_limpio

    if datos.descripcion is not None:
        categoria.descripcion = datos.descripcion

    if datos.activo is not None:
        categoria.activo = datos.activo

    db.commit()
    db.refresh(categoria)

    return categoria


def eliminar_categoria(
    db: Session,
    categoria_id: int
) -> Categoria:
    categoria = obtener_categoria_por_id(db, categoria_id)
    categoria.activo = False

    db.commit()
    db.refresh(categoria)

    return categoria
