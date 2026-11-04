"""
[Segundo Parcial] CU09 - Gestionar inventario
[Segundo Parcial] RF01 - Aislamiento Multitenant
[Segundo Parcial] RNF02 - Aislamiento de datos por empresa
Consumido por: Angular (admin-inventario) y Flutter (admin_inventario_page)
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol, get_current_empresa_id
from app.models.branch import Sucursal
from app.models.inventory import Inventario
from app.models.product import Producto
from app.models.product_variant import ProductoVariante
from app.schemas.inventory import (
    InventarioCrear,
    InventarioActualizar,
    InventarioRespuesta
)
from app.services import inventory_service

# ============================================================
# CU15 - Administrar Inventario
# RF20 - Actualizar automáticamente el inventario tras una venta
# RF21 - Controlar las existencias por sucursal
# RF22 - Registrar movimientos de inventario
# Consumido por: Angular (admin-inventario) y Flutter (admin_inventario_page)
# ============================================================
router = APIRouter(
    tags=["Inventario"]
)


# CU15 / RF21 - Consulta del stock disponible, filtrable por sucursal y variante
@router.get(
    "",
    response_model=List[InventarioRespuesta]
)
def listar_inventario(
    sucursal_id: Optional[int] = None,
    variante_id: Optional[int] = None,
    db: Session = Depends(obtener_db),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU09 - Gestionar inventario
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Listar inventario filtrando por sucursales de la empresa
    """
    sucursales_empresa = [s.id for s in db.query(Sucursal).filter(Sucursal.empresa_id == empresa_id).all()]
    if not sucursales_empresa:
        return []
    query = db.query(Inventario).filter(Inventario.sucursal_id.in_(sucursales_empresa))
    if sucursal_id is not None:
        if sucursal_id not in sucursales_empresa:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a esta sucursal")
        query = query.filter(Inventario.sucursal_id == sucursal_id)
    if variante_id is not None:
        query = query.filter(Inventario.variante_id == variante_id)
    return query.all()


# Consulta paginada y enriquecida (producto_nombre, variante_talla,
# variante_color, producto_imagen_url) para el panel admin web.
# IMPORTANTE: declararse antes de /{inventario_id} para que "detallado"
# no se interprete como un inventario_id.
@router.get(
    "/detallado",
    response_model=dict
)
def listar_inventario_detallado(
    sucursal_id: Optional[int] = None,
    page: int = 0,
    page_size: int = 20,
    db: Session = Depends(obtener_db),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU09 - Gestionar inventario
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    """
    if sucursal_id is not None:
        sucursal = db.query(Sucursal).filter(Sucursal.id == sucursal_id).first()
        if not sucursal or sucursal.empresa_id != empresa_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a esta sucursal")
    return inventory_service.listar_inventario_paginado(
        db,
        sucursal_id=sucursal_id,
        page=page,
        page_size=page_size
    )


@router.get(
    "/{inventario_id}",
    response_model=InventarioRespuesta
)
def obtener_inventario(
    inventario_id: int,
    db: Session = Depends(obtener_db),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU09 - Gestionar inventario
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    """
    inventario = db.query(Inventario).filter(Inventario.id == inventario_id).first()
    if not inventario:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Inventario not found")
    sucursal = db.query(Sucursal).filter(Sucursal.id == inventario.sucursal_id).first()
    if not sucursal or sucursal.empresa_id != empresa_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a este inventario")
    return inventario


@router.post(
    "",
    response_model=InventarioRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_inventario(
    datos: InventarioCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU09 - Gestionar inventario
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Validar que sucursal y variante pertenezcan a la misma empresa
    """
    sucursal = db.query(Sucursal).filter(Sucursal.id == datos.sucursal_id).first()
    if not sucursal or sucursal.empresa_id != empresa_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a esta sucursal")
    variante = db.query(ProductoVariante).filter(ProductoVariante.id == datos.variante_id).first()
    if not variante:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Variante not found")
    producto = db.query(Producto).filter(Producto.id == variante.producto_id).first()
    if not producto or producto.empresa_id != empresa_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="La variante no pertenece a esta empresa")
    return inventory_service.crear_inventario(
        db,
        datos
    )


@router.put(
    "/{inventario_id}",
    response_model=InventarioRespuesta
)
def actualizar_inventario(
    inventario_id: int,
    datos: InventarioActualizar,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU09 - Gestionar inventario
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Validar pertenencia a la empresa
    """
    inventario = db.query(Inventario).filter(Inventario.id == inventario_id).first()
    if not inventario:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Inventario not found")
    sucursal = db.query(Sucursal).filter(Sucursal.id == inventario.sucursal_id).first()
    if not sucursal or sucursal.empresa_id != empresa_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a este inventario")
    if datos.sucursal_id is not None:
        sucursal_nueva = db.query(Sucursal).filter(Sucursal.id == datos.sucursal_id).first()
        if not sucursal_nueva or sucursal_nueva.empresa_id != empresa_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a esta sucursal")
    if datos.variante_id is not None:
        variante = db.query(ProductoVariante).filter(ProductoVariante.id == datos.variante_id).first()
        if not variante:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Variante not found")
        producto = db.query(Producto).filter(Producto.id == variante.producto_id).first()
        if not producto or producto.empresa_id != empresa_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="La variante no pertenece a esta empresa")
    return inventory_service.actualizar_inventario(
        db,
        inventario_id,
        datos
    )


@router.delete(
    "/{inventario_id}",
    response_model=InventarioRespuesta
)
def eliminar_inventario(
    inventario_id: int,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU09 - Gestionar inventario
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Validar pertenencia a la empresa
    """
    inventario = db.query(Inventario).filter(Inventario.id == inventario_id).first()
    if not inventario:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Inventario not found")
    sucursal = db.query(Sucursal).filter(Sucursal.id == inventario.sucursal_id).first()
    if not sucursal or sucursal.empresa_id != empresa_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a este inventario")
    return inventory_service.eliminar_inventario(
        db,
        inventario_id
    )
