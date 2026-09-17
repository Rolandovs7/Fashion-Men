from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, obtener_usuario_actual
from app.models.user import Usuario
from app.schemas.cart import (
    DetalleCarritoCrear,
    DetalleCarritoActualizar,
    CarritoRespuesta
)
from app.services import cart_service

router = APIRouter(
    tags=["Carrito"]
)


@router.get(
    "",
    response_model=CarritoRespuesta
)
def obtener_mi_carrito(
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    return cart_service.obtener_carrito(
        db,
        usuario_actual.id
    )


@router.post(
    "/items",
    response_model=CarritoRespuesta
)
def agregar_item(
    datos: DetalleCarritoCrear,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    return cart_service.agregar_producto_al_carrito(
        db,
        usuario_actual.id,
        datos
    )


@router.put(
    "/items/{detalle_id}",
    response_model=CarritoRespuesta
)
def actualizar_item(
    detalle_id: int,
    datos: DetalleCarritoActualizar,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    return cart_service.actualizar_detalle_carrito(
        db,
        usuario_actual.id,
        detalle_id,
        datos
    )


@router.delete(
    "/items/{detalle_id}",
    response_model=CarritoRespuesta
)
def eliminar_item(
    detalle_id: int,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    return cart_service.eliminar_detalle_carrito(
        db,
        usuario_actual.id,
        detalle_id
    )


@router.delete(
    "",
    response_model=CarritoRespuesta
)
def vaciar_carrito(
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    return cart_service.vaciar_carrito(
        db,
        usuario_actual.id
    )
