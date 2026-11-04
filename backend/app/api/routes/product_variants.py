"""
[Segundo Parcial] CU06 - Gestionar catálogo
[Segundo Parcial] RF01 - Aislamiento Multitenant
[Segundo Parcial] RNF02 - Aislamiento de datos por empresa
Consumido por: Frontend (Admin)
"""
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol, get_current_empresa_id
from app.models.product import Producto
from app.models.product_variant import ProductoVariante
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
    db: Session = Depends(obtener_db),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU06 - Gestionar catálogo
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Listar las variantes (talla + color) de un producto, con su stock disponible
    """
    producto = db.query(Producto).filter(Producto.id == producto_id).first()
    if not producto:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Producto not found")
    if producto.empresa_id != empresa_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a este producto")
    return product_variant_service.listar_variantes_por_producto(
        db, producto_id, solo_activos=solo_activos
    )


@router.get(
    "/{variante_id}",
    response_model=VarianteRespuesta
)
def obtener_variante(
    variante_id: int,
    db: Session = Depends(obtener_db),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU06 - Gestionar catálogo
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Obtener una variante por su ID, con su stock disponible
    """
    variante = db.query(ProductoVariante).filter(ProductoVariante.id == variante_id).first()
    if not variante:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Variante not found")
    producto = db.query(Producto).filter(Producto.id == variante.producto_id).first()
    if not producto or producto.empresa_id != empresa_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a esta variante")
    return product_variant_service.obtener_variante_respuesta_por_id(db, variante_id)


@router.post(
    "",
    response_model=VarianteRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_variante(
    datos: VarianteCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU06 - Gestionar catálogo
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Crear una nueva variante de producto (solo administradores) verificando pertenencia
    """
    producto = db.query(Producto).filter(Producto.id == datos.producto_id).first()
    if not producto:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Producto not found")
    if producto.empresa_id != empresa_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a este producto")
    return product_variant_service.crear_variante(db, datos)


@router.put(
    "/{variante_id}",
    response_model=VarianteRespuesta
)
def actualizar_variante(
    variante_id: int,
    datos: VarianteActualizar,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU06 - Gestionar catálogo
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Actualizar/activar una variante verificando pertenencia
    """
    variante = db.query(ProductoVariante).filter(ProductoVariante.id == variante_id).first()
    if not variante:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Variante not found")
    producto = db.query(Producto).filter(Producto.id == variante.producto_id).first()
    if not producto or producto.empresa_id != empresa_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a esta variante")
    return product_variant_service.actualizar_variante(db, variante_id, datos)


@router.delete(
    "/{variante_id}",
    response_model=VarianteRespuesta
)
def eliminar_variante(
    variante_id: int,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU06 - Gestionar catálogo
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Eliminar (desactivar) una variante verificando pertenencia
    """
    variante = db.query(ProductoVariante).filter(ProductoVariante.id == variante_id).first()
    if not variante:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Variante not found")
    producto = db.query(Producto).filter(Producto.id == variante.producto_id).first()
    if not producto or producto.empresa_id != empresa_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a esta variante")
    return product_variant_service.eliminar_variante(db, variante_id)
