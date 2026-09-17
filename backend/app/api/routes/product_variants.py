from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol
from app.schemas.product_variant import (
    VarianteCrear,
    VarianteActualizar,
    VarianteRespuesta
)
from app.services import product_variant_service

router = APIRouter(
    tags=["Variantes"]
)


@router.get(
    "/producto/{producto_id}",
    response_model=List[VarianteRespuesta]
)
def listar_variantes_por_producto(
    producto_id: int,
    solo_activos: bool = True,
    db: Session = Depends(obtener_db)
):
    """Listar las variantes (talla + color) de un producto, con su stock disponible"""
    return product_variant_service.listar_variantes_por_producto(
        db, producto_id, solo_activos=solo_activos
    )


@router.get(
    "/{variante_id}",
    response_model=VarianteRespuesta
)
def obtener_variante(
    variante_id: int,
    db: Session = Depends(obtener_db)
):
    """Obtener una variante por su ID, con su stock disponible"""
    return product_variant_service.obtener_variante_respuesta_por_id(db, variante_id)


@router.post(
    "",
    response_model=VarianteRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_variante(
    datos: VarianteCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Crear una nueva variante de producto (solo administradores)"""
    return product_variant_service.crear_variante(db, datos)


@router.put(
    "/{variante_id}",
    response_model=VarianteRespuesta
)
def actualizar_variante(
    variante_id: int,
    datos: VarianteActualizar,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Activar/desactivar una variante (solo administradores)"""
    return product_variant_service.actualizar_variante(db, variante_id, datos)


@router.delete(
    "/{variante_id}",
    response_model=VarianteRespuesta
)
def eliminar_variante(
    variante_id: int,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Eliminar (desactivar) una variante (solo administradores)"""
    return product_variant_service.eliminar_variante(db, variante_id)
