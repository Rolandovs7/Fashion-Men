from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol
from app.schemas.product import (
    ProductoCrear,
    ProductoActualizar,
    ProductoRespuesta
)
from app.services import product_service

router = APIRouter(
    tags=["Productos"]
)


@router.get(
    "/",
    response_model=List[ProductoRespuesta]
)
def listar_productos(
    db: Session = Depends(obtener_db)
):
    """Listar todos los productos activos"""
    return product_service.listar_productos(db)


@router.get(
    "/{producto_id}",
    response_model=ProductoRespuesta
)
def obtener_producto(
    producto_id: int,
    db: Session = Depends(obtener_db)
):
    """Obtener un producto por su ID"""
    return product_service.obtener_producto_por_id(db, producto_id)


@router.post(
    "/",
    response_model=ProductoRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_producto(
    datos: ProductoCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Crear un nuevo producto (solo administradores)"""
    return product_service.crear_producto(db, datos)


@router.put(
    "/{producto_id}",
    response_model=ProductoRespuesta
)
def actualizar_producto(
    producto_id: int,
    datos: ProductoActualizar,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Actualizar un producto existente (solo administradores)"""
    return product_service.actualizar_producto(db, producto_id, datos)


@router.delete(
    "/{producto_id}",
    status_code=status.HTTP_204_NO_CONTENT
)
def eliminar_producto(
    producto_id: int,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Eliminar (desactivar) un producto (solo administradores)"""
    return product_service.eliminar_producto(db, producto_id)