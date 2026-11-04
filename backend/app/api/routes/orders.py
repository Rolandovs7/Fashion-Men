"""
[Segundo Parcial] CU10 - Gestionar ventas presenciales
[Segundo Parcial] CU13 - Registrarse como cliente y comprar
[Segundo Parcial] RNF02 - Aislamiento de datos por empresa
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, obtener_usuario_actual, requerir_rol, get_current_empresa_id
from app.models.branch import Sucursal
from app.models.product import Producto
from app.models.product_variant import ProductoVariante
from app.models.user import Usuario
from app.schemas.order import (
    PedidoCrear,
    PedidoCambiarEstadoAdmin,
    PedidoRespuesta,
    VentaPresencialCrear
)
from app.services import order_service

router = APIRouter(
    tags=["Pedidos"]
)


@router.post(
    "/venta-presencial",
    response_model=PedidoRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_venta_presencial(
    datos: VentaPresencialCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU10 - Gestionar ventas presenciales
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Registrar una venta presencial en punto de caja (RF17/RF18)
    """
    if datos.sucursal_id is not None:
        sucursal = db.query(Sucursal).filter(Sucursal.id == datos.sucursal_id).first()
        if not sucursal or sucursal.empresa_id != empresa_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sucursal no pertenece a su empresa")
    # Validar productos/variantes pertenezcan a la empresa
    for item in datos.items:
        variante = db.query(ProductoVariante).filter(ProductoVariante.id == item.variante_id).first()
        if not variante:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Variante no encontrada")
        producto = db.query(Producto).filter(Producto.id == variante.producto_id).first()
        if not producto or producto.empresa_id != empresa_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Producto no pertenece a su empresa")
    return order_service.crear_venta_presencial(db, datos)


@router.get(
    "",
    response_model=List[PedidoRespuesta]
)
def listar_mis_pedidos(
    estado: Optional[str] = None,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    """
    [Segundo Parcial] CU13 - Registrarse como cliente y comprar
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    """
    return order_service.listar_pedidos_usuario(
        db,
        usuario_actual.id,
        estado=estado
    )


@router.get(
    "/admin/todos",
    response_model=List[PedidoRespuesta]
)
def listar_todos_los_pedidos(
    estado: Optional[str] = None,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU10 - Gestionar ventas presenciales
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Listar todos los pedidos de la empresa (solo administradores)
    """
    from app.models.order import Pedido
    query = db.query(Pedido).filter(Pedido.empresa_id == empresa_id)
    if estado:
        query = query.filter(Pedido.estado == estado)
    return query.all()


@router.get(
    "/me",
    response_model=List[PedidoRespuesta]
)
def listar_mis_pedidos_alias(
    estado: Optional[str] = None,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    """
    CU33 - Gestionar Historial de Compras (alias /me)
    [Segundo Parcial] CU13 - Registrarse como cliente y comprar
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    RF15/RF16 - Historial de compras del usuario autenticado.
    Alias de GET /api/pedidos para compatibilidad con la documentación.
    """
    return order_service.listar_pedidos_usuario(
        db,
        usuario_actual.id,
        estado=estado
    )


@router.get(
    "/{pedido_id}",
    response_model=PedidoRespuesta
)
def obtener_mi_pedido(
    pedido_id: int,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    """
    [Segundo Parcial] CU13 - Registrarse como cliente y comprar
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    """
    return order_service.obtener_pedido_por_id(
        db,
        usuario_actual.id,
        pedido_id
    )


@router.post(
    "",
    response_model=PedidoRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_pedido_desde_carrito(
    datos: PedidoCrear,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    """
    [Segundo Parcial] CU13 - Registrarse como cliente y comprar
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    """
    return order_service.crear_pedido_desde_carrito(
        db,
        usuario_actual.id,
        datos
    )


@router.put(
    "/{pedido_id}/cancelar",
    response_model=PedidoRespuesta
)
def cancelar_mi_pedido(
    pedido_id: int,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    return order_service.cancelar_pedido_cliente(
        db,
        usuario_actual.id,
        pedido_id
    )


@router.put(
    "/{pedido_id}/estado",
    response_model=PedidoRespuesta
)
def cambiar_estado_pedido_admin(
    pedido_id: int,
    datos: PedidoCambiarEstadoAdmin,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    return order_service.cambiar_estado_pedido_admin(
        db,
        pedido_id,
        datos
    )
