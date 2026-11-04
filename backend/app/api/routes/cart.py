"""
[Segundo Parcial] CU13 - Registrarse como cliente y comprar
[Segundo Parcial] RNF02 - Aislamiento de datos por empresa
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, obtener_usuario_actual, get_current_empresa_id
from app.models.product import Producto
from app.models.product_variant import ProductoVariante
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
    """
    [Segundo Parcial] CU13 - Registrarse como cliente y comprar
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    """
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
    db: Session = Depends(obtener_db),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU13 - Registrarse como cliente y comprar
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Validar que el producto pertenezca a la empresa del cliente
    """
    variante = db.query(ProductoVariante).filter(ProductoVariante.id == datos.variante_id).first()
    if not variante:
        raise HTTPException(status_code=404, detail="Variante no encontrada")
    producto = db.query(Producto).filter(Producto.id == variante.producto_id).first()
    if not producto or producto.empresa_id != empresa_id:
        raise HTTPException(status_code=403, detail="Producto no pertenece a su empresa")
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
