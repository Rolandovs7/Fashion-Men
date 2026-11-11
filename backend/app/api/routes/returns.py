"""
[Segundo Parcial] CU12 - Gestionar cambio de prendas (Devoluciones)
[Segundo Parcial] RNF02 - Aislamiento de datos por empresa
"""
import logging
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, obtener_usuario_actual, requerir_rol, get_current_empresa_id
from app.models.order import Pedido
from app.models.product_variant import ProductoVariante
from app.models.user import Usuario
from app.schemas.return_schema import (
    DevolucionSolicitar,
    DevolucionCambiarEstadoAdmin,
    DevolucionRespuesta
)
from app.services import return_service
from app.services.email_service import enviar_correo_devolucion

logger = logging.getLogger(__name__)

router = APIRouter(
    tags=["Devoluciones"]
)


def _nombre_producto_devolucion(db: Session, variante_id: int) -> str:
    """Nombre del producto devuelto a partir de la variante del pedido."""
    variante = (
        db.query(ProductoVariante)
        .filter(ProductoVariante.id == variante_id)
        .first()
    )
    if variante and variante.producto and variante.producto.nombre:
        return variante.producto.nombre
    return "tu producto"


def _notificar_devolucion_cliente(db: Session, devolucion, estado: str) -> None:
    """
    Envía el correo de devolución al cliente del pedido original.

    Best-effort: cualquier fallo (sin email, sin pedido, Brevo caído)
    se registra en el log y se ignora para no romper la devolución.
    """
    try:
        pedido = db.query(Pedido).filter(Pedido.id == devolucion.pedido_id).first()
        if not pedido:
            logger.warning(
                "Devolución %s sin pedido asociado; no se envía correo.",
                devolucion.id,
            )
            return

        cliente = db.query(Usuario).filter(Usuario.id == pedido.usuario_id).first()
        if not cliente or not cliente.email:
            logger.warning(
                "Pedido %s sin email de cliente; no se envía correo de devolución.",
                pedido.id,
            )
            return

        nombre_producto = _nombre_producto_devolucion(db, devolucion.variante_id)
        enviar_correo_devolucion(cliente.email, nombre_producto, estado)
    except Exception as e:
        logger.error(
            "No se pudo enviar el correo de la devolución %s: %s",
            getattr(devolucion, "id", "?"),
            e,
        )
        print(f"❌ No se pudo enviar el correo de devolución: {e}")


@router.get(
    "",
    response_model=List[DevolucionRespuesta]
)
def listar_mis_devoluciones(
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    """
    [Segundo Parcial] CU12 - Gestionar cambio de prendas (Devoluciones)
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    """
    return return_service.listar_devoluciones_usuario(
        db,
        usuario_actual.id
    )


@router.get(
    "/{devolucion_id}",
    response_model=DevolucionRespuesta
)
def obtener_mi_devolucion(
    devolucion_id: int,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db)
):
    """
    [Segundo Parcial] CU12 - Gestionar cambio de prendas (Devoluciones)
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    """
    return return_service.obtener_devolucion_por_id(
        db,
        usuario_actual.id,
        devolucion_id
    )


@router.post(
    "",
    response_model=DevolucionRespuesta,
    status_code=status.HTTP_201_CREATED
)
def solicitar_devolucion(
    datos: DevolucionSolicitar,
    usuario_actual: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_db),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU12 - Gestionar cambio de prendas (Devoluciones)
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Validar que el pedido/venta original pertenezca a la empresa
    """
    pedido = db.query(Pedido).filter(Pedido.id == datos.pedido_id).first()
    if not pedido:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pedido not found")
    if pedido.empresa_id != empresa_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Pedido no pertenece a su empresa")
    return return_service.solicitar_devolucion(
        db,
        usuario_actual.id,
        datos
    )


@router.put(
    "/{devolucion_id}/estado",
    response_model=DevolucionRespuesta
)
def cambiar_estado_devolucion_admin(
    devolucion_id: int,
    datos: DevolucionCambiarEstadoAdmin,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU12 - Gestionar cambio de prendas (Devoluciones)
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    """
    from app.models.return_model import Devolucion
    devolucion = db.query(Devolucion).filter(Devolucion.id == devolucion_id).first()
    if not devolucion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Devolución not found")
    if devolucion.empresa_id != empresa_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Devolución no pertenece a su empresa")

    # Guardamos el estado previo: el servicio muta la misma instancia.
    estado_anterior = devolucion.estado

    devolucion_actualizada = return_service.cambiar_estado_devolucion_admin(
        db,
        devolucion_id,
        datos
    )

    # Avisar al cliente cuando la devolución queda aprobada o completada.
    # En la rama 'completada' el servicio ya repuso el stock antes de
    # retornar. Si el correo falla, la devolución ya quedó guardada y la
    # respuesta no se rompe.
    estado_nuevo = (devolucion_actualizada.estado or "").strip().lower()
    if estado_nuevo in ("aprobada", "completada") and estado_nuevo != estado_anterior:
        _notificar_devolucion_cliente(db, devolucion_actualizada, estado_nuevo)

    return devolucion_actualizada
