from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.cart import Carrito
from app.models.cart_detail import DetalleCarrito
from app.models.product_variant import ProductoVariante
from app.models.inventory import Inventario
from app.models.branch import Sucursal
from app.schemas.cart import DetalleCarritoCrear, DetalleCarritoActualizar


def calcular_stock_disponible(db: Session, variante_id: int) -> int:
    inventarios = db.query(Inventario).join(
        Sucursal, Inventario.sucursal_id == Sucursal.id
    ).filter(
        Inventario.variante_id == variante_id,
        Sucursal.activo.is_(True)
    ).all()

    disponible = sum(
        max(0, inv.cantidad - inv.cantidad_reservada)
        for inv in inventarios
    )
    return disponible


def obtener_o_crear_carrito(db: Session, usuario_id: int) -> Carrito:
    carrito = db.query(Carrito).filter(
        Carrito.usuario_id == usuario_id
    ).first()

    if not carrito:
        carrito = Carrito(usuario_id=usuario_id)
        db.add(carrito)
        db.commit()
        db.refresh(carrito)

    return carrito


def obtener_carrito(db: Session, usuario_id: int) -> Carrito:
    return obtener_o_crear_carrito(db, usuario_id)


def agregar_producto_al_carrito(
    db: Session,
    usuario_id: int,
    datos: DetalleCarritoCrear
) -> Carrito:
    if datos.cantidad <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La cantidad debe ser mayor a 0"
        )

    variante = db.query(ProductoVariante).filter(
        ProductoVariante.id == datos.variante_id
    ).first()

    if not variante or not variante.activo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La variante especificada no existe o está inactiva"
        )

    stock_disponible = calcular_stock_disponible(db, datos.variante_id)

    carrito = obtener_o_crear_carrito(db, usuario_id)

    detalle_existente = db.query(DetalleCarrito).filter(
        DetalleCarrito.carrito_id == carrito.id,
        DetalleCarrito.variante_id == datos.variante_id
    ).first()

    cantidad_deseada = datos.cantidad
    if detalle_existente:
        cantidad_deseada += detalle_existente.cantidad

    if cantidad_deseada > stock_disponible:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Stock insuficiente. Disponible: {stock_disponible}"
        )

    if detalle_existente:
        detalle_existente.cantidad = cantidad_deseada
    else:
        nuevo_detalle = DetalleCarrito(
            carrito_id=carrito.id,
            variante_id=datos.variante_id,
            cantidad=datos.cantidad
        )
        db.add(nuevo_detalle)

    db.commit()
    db.refresh(carrito)

    return carrito


def actualizar_detalle_carrito(
    db: Session,
    usuario_id: int,
    detalle_id: int,
    datos: DetalleCarritoActualizar
) -> Carrito:
    if datos.cantidad <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La cantidad debe ser mayor a 0"
        )

    carrito = obtener_o_crear_carrito(db, usuario_id)

    detalle = db.query(DetalleCarrito).filter(
        DetalleCarrito.id == detalle_id,
        DetalleCarrito.carrito_id == carrito.id
    ).first()

    if not detalle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Elemento del carrito no encontrado"
        )

    stock_disponible = calcular_stock_disponible(db, detalle.variante_id)

    if datos.cantidad > stock_disponible:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Stock insuficiente. Disponible: {stock_disponible}"
        )

    detalle.cantidad = datos.cantidad

    db.commit()
    db.refresh(carrito)

    return carrito


def eliminar_detalle_carrito(
    db: Session,
    usuario_id: int,
    detalle_id: int
) -> Carrito:
    carrito = obtener_o_crear_carrito(db, usuario_id)

    detalle = db.query(DetalleCarrito).filter(
        DetalleCarrito.id == detalle_id,
        DetalleCarrito.carrito_id == carrito.id
    ).first()

    if not detalle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Elemento del carrito no encontrado"
        )

    db.delete(detalle)
    db.commit()
    db.refresh(carrito)

    return carrito


def vaciar_carrito(db: Session, usuario_id: int) -> Carrito:
    carrito = obtener_o_crear_carrito(db, usuario_id)

    db.query(DetalleCarrito).filter(
        DetalleCarrito.carrito_id == carrito.id
    ).delete(synchronize_session=False)

    db.commit()
    db.refresh(carrito)

    return carrito
