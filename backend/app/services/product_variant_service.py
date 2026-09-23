from typing import List, Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.product import Producto
from app.models.product_variant import ProductoVariante
from app.models.size import Talla
from app.models.color import Color
from app.models.inventory import Inventario
from app.models.branch import Sucursal
from app.schemas.product_variant import VarianteCrear, VarianteActualizar


def _calcular_stock_disponible(db: Session, variante_id: int) -> int:
    inventarios = db.query(Inventario).join(
        Sucursal, Inventario.sucursal_id == Sucursal.id
    ).filter(
        Inventario.variante_id == variante_id,
        Sucursal.activo.is_(True)
    ).all()

    return sum(
        max(0, inv.cantidad - inv.cantidad_reservada)
        for inv in inventarios
    )


def _serializar_variante(db: Session, variante: ProductoVariante) -> dict:
    talla = db.query(Talla).filter(Talla.id == variante.talla_id).first()
    color = db.query(Color).filter(Color.id == variante.color_id).first()

    return {
        "id": variante.id,
        "producto_id": variante.producto_id,
        "talla_id": variante.talla_id,
        "talla_nombre": talla.nombre if talla else "—",
        "color_id": variante.color_id,
        "color_nombre": color.nombre if color else "—",
        "color_codigo_hex": color.codigo_hex if color else None,
        "color_imagen_url": color.imagen_url if color else None,
        "activo": variante.activo,
        "stock_disponible": _calcular_stock_disponible(db, variante.id)
    }


def listar_variantes_por_producto(
    db: Session,
    producto_id: int,
    solo_activos: bool = True
) -> List[dict]:
    query = db.query(ProductoVariante).filter(
        ProductoVariante.producto_id == producto_id
    )

    if solo_activos:
        query = query.filter(ProductoVariante.activo.is_(True))

    variantes = query.all()

    return [_serializar_variante(db, v) for v in variantes]


def obtener_variante_por_id(db: Session, variante_id: int) -> ProductoVariante:
    variante = db.query(ProductoVariante).filter(
        ProductoVariante.id == variante_id
    ).first()

    if not variante:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Variante no encontrada"
        )
    return variante


def obtener_variante_respuesta_por_id(db: Session, variante_id: int) -> dict:
    variante = obtener_variante_por_id(db, variante_id)
    return _serializar_variante(db, variante)


def crear_variante(db: Session, datos: VarianteCrear) -> dict:
    producto = db.query(Producto).filter(
        Producto.id == datos.producto_id
    ).first()
    if not producto:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El producto especificado no existe"
        )

    talla = db.query(Talla).filter(Talla.id == datos.talla_id).first()
    if not talla:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La talla especificada no existe"
        )

    color = db.query(Color).filter(Color.id == datos.color_id).first()
    if not color:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El color especificado no existe"
        )

    existente = db.query(ProductoVariante).filter(
        ProductoVariante.producto_id == datos.producto_id,
        ProductoVariante.talla_id == datos.talla_id,
        ProductoVariante.color_id == datos.color_id
    ).first()

    if existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe una variante con esa talla y color para este producto"
        )

    nueva_variante = ProductoVariante(
        producto_id=datos.producto_id,
        talla_id=datos.talla_id,
        color_id=datos.color_id,
        activo=True
    )

    db.add(nueva_variante)
    db.commit()
    db.refresh(nueva_variante)

    return _serializar_variante(db, nueva_variante)


def actualizar_variante(
    db: Session,
    variante_id: int,
    datos: VarianteActualizar
) -> dict:
    variante = obtener_variante_por_id(db, variante_id)

    if datos.activo is not None:
        variante.activo = datos.activo

    db.commit()
    db.refresh(variante)

    return _serializar_variante(db, variante)


def eliminar_variante(db: Session, variante_id: int) -> dict:
    variante = obtener_variante_por_id(db, variante_id)
    variante.activo = False

    db.commit()
    db.refresh(variante)

    return _serializar_variante(db, variante)
