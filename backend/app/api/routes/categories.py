from typing import List, Optional
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol
from app.schemas.category import (
    CategoriaCrear,
    CategoriaActualizar,
    CategoriaRespuesta
)
from app.services import category_service

router = APIRouter(
    tags=["Categorías"]
)


@router.get(
    "",
    response_model=List[CategoriaRespuesta]
)
def listar_categorias(
    solo_activos: Optional[bool] = False,
    db: Session = Depends(obtener_db)
):
    return category_service.listar_categorias(
        db,
        solo_activos=solo_activos
    )


@router.get(
    "/{categoria_id}",
    response_model=CategoriaRespuesta
)
def obtener_categoria(
    categoria_id: int,
    db: Session = Depends(obtener_db)
):
    return category_service.obtener_categoria_por_id(
        db,
        categoria_id
    )


@router.post(
    "",
    response_model=CategoriaRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_categoria(
    datos: CategoriaCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    return category_service.crear_categoria(
        db,
        datos
    )


@router.put(
    "/{categoria_id}",
    response_model=CategoriaRespuesta
)
def actualizar_categoria(
    categoria_id: int,
    datos: CategoriaActualizar,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    return category_service.actualizar_categoria(
        db,
        categoria_id,
        datos
    )


@router.delete(
    "/{categoria_id}",
    response_model=CategoriaRespuesta
)
def eliminar_categoria(
    categoria_id: int,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    return category_service.eliminar_categoria(
        db,
        categoria_id
    )
