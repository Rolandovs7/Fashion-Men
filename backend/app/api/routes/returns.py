"""
[Segundo Parcial] CU12 - Gestionar cambio de prendas (Devoluciones)
[Segundo Parcial] RNF02 - Aislamiento de datos por empresa
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, obtener_usuario_actual, requerir_rol, get_current_empresa_id
from app.models.order import Pedido
from app.models.user import Usuario
from app.schemas.return_schema import (
    DevolucionSolicitar,
    DevolucionCambiarEstadoAdmin,
    DevolucionRespuesta
)
from app.services import return_service

router = APIRouter(
    tags=["Devoluciones"]
)


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
    return return_service.cambiar_estado_devolucion_admin(
        db,
        devolucion_id,
        datos
    )
