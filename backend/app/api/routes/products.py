"""
[Segundo Parcial] CU06 - Gestionar catálogo
[Segundo Parcial] CU07 - Consultar catálogo
[Segundo Parcial] CU27 - Gestionar listas de precios
[Segundo Parcial] RF01 - Aislamiento Multitenant
[Segundo Parcial] RNF02 - Aislamiento de datos por empresa
Consumido por: Frontend (Admin/Cliente)
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.core.dependencies import obtener_db, requerir_rol, get_current_empresa_id
from app.models.product import Producto
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
    db: Session = Depends(obtener_db),
    empresa_id: int = Depends(get_current_empresa_id),
    categoria_id: Optional[int] = None,
    marca_id: Optional[int] = None,
    tipo_prenda_id: Optional[int] = None,
    coleccion_id: Optional[int] = None,
    temporada_id: Optional[int] = None,
    proveedor_id: Optional[int] = None,
    solo_activos: bool = True
):
    """
    [Segundo Parcial] CU07 - Consultar catálogo
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Listar productos de la empresa con filtros y optimización
    """
    query = db.query(Producto).options(
        joinedload(Producto.variantes) if hasattr(Producto, 'variantes') else joinedload(Producto)
    ).filter(Producto.empresa_id == empresa_id)
    if solo_activos:
        query = query.filter(Producto.activo == True)
    if categoria_id is not None:
        query = query.filter(Producto.categoria_id == categoria_id)
    if marca_id is not None:
        query = query.filter(Producto.marca_id == marca_id)
    if tipo_prenda_id is not None:
        query = query.filter(Producto.tipo_prenda_id == tipo_prenda_id)
    if coleccion_id is not None:
        query = query.filter(Producto.coleccion_id == coleccion_id)
    if temporada_id is not None:
        query = query.filter(Producto.temporada_id == temporada_id)
    if proveedor_id is not None:
        query = query.filter(Producto.proveedor_id == proveedor_id)
    return query.all()


@router.get(
    "/{producto_id}",
    response_model=ProductoRespuesta
)
def obtener_producto(
    producto_id: int,
    db: Session = Depends(obtener_db),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU07 - Consultar catálogo
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Obtener un producto por su ID
    """
    producto = db.query(Producto).filter(Producto.id == producto_id).first()
    if not producto:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Producto not found")
    if producto.empresa_id != empresa_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a este producto")
    return producto


@router.post(
    "/",
    response_model=ProductoRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_producto(
    datos: ProductoCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU06 - Gestionar catálogo
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Crear un nuevo producto (solo administradores) asignando empresa_id
    """
    producto = Producto(
        nombre=datos.nombre,
        descripcion=datos.descripcion,
        imagen_url=datos.imagen_url,
        modelo_ar_url=datos.modelo_ar_url,
        precio=datos.precio,
        precio_mayorista=datos.precio_mayorista,
        cantidad_mayorista=datos.cantidad_mayorista,
        categoria_id=datos.categoria_id,
        proveedor_id=datos.proveedor_id,
        temporada_id=datos.temporada_id,
        coleccion_id=datos.coleccion_id,
        tipo_prenda_id=datos.tipo_prenda_id,
        marca_id=datos.marca_id,
        descuento_id=datos.descuento_id,
        empresa_id=empresa_id,
        activo=datos.activo if datos.activo is not None else True
    )
    db.add(producto)
    db.commit()
    db.refresh(producto)
    return producto


@router.put(
    "/{producto_id}",
    response_model=ProductoRespuesta
)
def actualizar_producto(
    producto_id: int,
    datos: ProductoActualizar,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU06 - Gestionar catálogo
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Actualizar un producto existente verificando pertenencia a la empresa
    """
    producto = db.query(Producto).filter(Producto.id == producto_id).first()
    if not producto:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Producto not found")
    if producto.empresa_id != empresa_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a este producto")

    if datos.nombre is not None:
        producto.nombre = datos.nombre
    if datos.descripcion is not None:
        producto.descripcion = datos.descripcion
    if datos.imagen_url is not None:
        producto.imagen_url = datos.imagen_url
    if datos.modelo_ar_url is not None:
        producto.modelo_ar_url = datos.modelo_ar_url
    if datos.precio is not None:
        producto.precio = datos.precio
    if datos.precio_mayorista is not None:
        producto.precio_mayorista = datos.precio_mayorista
    if datos.cantidad_mayorista is not None:
        producto.cantidad_mayorista = datos.cantidad_mayorista
    if datos.categoria_id is not None:
        producto.categoria_id = datos.categoria_id
    if datos.proveedor_id is not None:
        producto.proveedor_id = datos.proveedor_id
    if datos.temporada_id is not None:
        producto.temporada_id = datos.temporada_id
    if datos.coleccion_id is not None:
        producto.coleccion_id = datos.coleccion_id
    if datos.tipo_prenda_id is not None:
        producto.tipo_prenda_id = datos.tipo_prenda_id
    if datos.marca_id is not None:
        producto.marca_id = datos.marca_id
    if datos.descuento_id is not None:
        producto.descuento_id = datos.descuento_id
    if datos.activo is not None:
        producto.activo = datos.activo

    db.commit()
    db.refresh(producto)
    return producto


@router.delete(
    "/{producto_id}",
    status_code=status.HTTP_204_NO_CONTENT
)
def eliminar_producto(
    producto_id: int,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU06 - Gestionar catálogo
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Eliminar (desactivar) un producto verificando pertenencia a la empresa
    """
    producto = db.query(Producto).filter(Producto.id == producto_id).first()
    if not producto:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Producto not found")
    if producto.empresa_id != empresa_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a este producto")
    producto.activo = False
    db.commit()
    return None
