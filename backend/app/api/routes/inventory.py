from typing import List, Optional
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol
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
    db: Session = Depends(obtener_db)
):
    return inventory_service.listar_inventario(
        db,
        sucursal_id=sucursal_id,
        variante_id=variante_id
    )


@router.get(
    "/{inventario_id}",
    response_model=InventarioRespuesta
)
def obtener_inventario(
    inventario_id: int,
    db: Session = Depends(obtener_db)
):
    return inventory_service.obtener_inventario_por_id(
        db,
        inventario_id
    )


@router.post(
    "",
    response_model=InventarioRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_inventario(
    datos: InventarioCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
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
    _usuario_admin=Depends(requerir_rol("administrador"))
):
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
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    return inventory_service.eliminar_inventario(
        db,
        inventario_id
    )
