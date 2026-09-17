from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.inventory import Inventario
from app.models.product_variant import ProductoVariante
from app.models.branch import Sucursal
from app.schemas.inventory import InventarioCrear, InventarioActualizar


def listar_inventario(
    db: Session,
    sucursal_id: Optional[int] = None,
    variante_id: Optional[int] = None
) -> List[Inventario]:
    query = db.query(Inventario)

    if sucursal_id is not None:
        query = query.filter(Inventario.sucursal_id == sucursal_id)

    if variante_id is not None:
        query = query.filter(Inventario.variante_id == variante_id)

    return query.all()


def obtener_inventario_por_id(
    db: Session,
    inventario_id: int
) -> Inventario:
    inventario = db.query(Inventario).filter(
        Inventario.id == inventario_id
    ).first()

    if not inventario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Registro de inventario no encontrado"
        )
    return inventario


def crear_inventario(
    db: Session,
    datos: InventarioCrear
) -> Inventario:
    if datos.cantidad < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La cantidad no puede ser negativa"
        )

    if datos.cantidad_reservada < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La cantidad reservada no puede ser negativa"
        )

    if datos.cantidad_reservada > datos.cantidad:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La cantidad reservada no puede ser mayor que la cantidad total"
        )

    variante = db.query(ProductoVariante).filter(
        ProductoVariante.id == datos.variante_id
    ).first()

    if not variante or not variante.activo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La variante de producto no existe o está inactiva"
        )

    sucursal = db.query(Sucursal).filter(
        Sucursal.id == datos.sucursal_id
    ).first()

    if not sucursal or not sucursal.activo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La sucursal no existe o está inactiva"
        )

    existente = db.query(Inventario).filter(
        Inventario.variante_id == datos.variante_id,
        Inventario.sucursal_id == datos.sucursal_id
    ).first()

    if existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe un registro de inventario para esta variante en esta sucursal"
        )

    nuevo_inventario = Inventario(
        variante_id=datos.variante_id,
        sucursal_id=datos.sucursal_id,
        cantidad=datos.cantidad,
        cantidad_reservada=datos.cantidad_reservada
    )

    db.add(nuevo_inventario)
    db.commit()
    db.refresh(nuevo_inventario)

    return nuevo_inventario


def actualizar_inventario(
    db: Session,
    inventario_id: int,
    datos: InventarioActualizar
) -> Inventario:
    inventario = obtener_inventario_por_id(db, inventario_id)

    nueva_cantidad = datos.cantidad if datos.cantidad is not None else inventario.cantidad
    nueva_reservada = datos.cantidad_reservada if datos.cantidad_reservada is not None else inventario.cantidad_reservada

    if nueva_cantidad < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La cantidad no puede ser negativa"
        )

    if nueva_reservada < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La cantidad reservada no puede ser negativa"
        )

    if nueva_reservada > nueva_cantidad:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La cantidad reservada no puede ser mayor que la cantidad total"
        )

    inventario.cantidad = nueva_cantidad
    inventario.cantidad_reservada = nueva_reservada

    db.commit()
    db.refresh(inventario)

    return inventario


def eliminar_inventario(
    db: Session,
    inventario_id: int
) -> Inventario:
    inventario = obtener_inventario_por_id(db, inventario_id)

    db.delete(inventario)
    db.commit()

    return inventario
