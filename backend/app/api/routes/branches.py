"""
[Segundo Parcial] CU05 - Gestionar sucursales
[Segundo Parcial] RN-SaaS-01 - Límite de sucursales por plan
[Segundo Parcial] RF01 - Gestión Multitenant y Empresas
Consumido por: Frontend (Admin)
"""
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol, get_current_empresa_id, obtener_usuario_actual
from app.models.branch import Sucursal
from app.models.saas import Plan, Suscripcion
from app.schemas.branch import (
    SucursalCrear,
    SucursalActualizar,
    SucursalRespuesta
)
from app.services import branch_service

router = APIRouter(
    tags=["Sucursales"]
)


@router.get(
    "",
    response_model=List[SucursalRespuesta]
)
def listar_sucursales(
    solo_activos: bool = True,
    db: Session = Depends(obtener_db),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU05 - Gestionar sucursales
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Listar las sucursales de la empresa del usuario logueado
    """
    query = db.query(Sucursal).filter(Sucursal.empresa_id == empresa_id)
    if solo_activos:
        query = query.filter(Sucursal.activo == True)
    return query.all()


@router.get(
    "/{sucursal_id}",
    response_model=SucursalRespuesta
)
def obtener_sucursal(
    sucursal_id: int,
    db: Session = Depends(obtener_db),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU05 - Gestionar sucursales
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Obtener una sucursal por su ID
    """
    sucursal = db.query(Sucursal).filter(Sucursal.id == sucursal_id).first()
    if not sucursal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sucursal no encontrada")
    if sucursal.empresa_id != empresa_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a esta sucursal")
    return sucursal


@router.post(
    "",
    response_model=SucursalRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear_sucursal(
    datos: SucursalCrear,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador")),
    usuario_actual=Depends(obtener_usuario_actual),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU05 - Gestionar sucursales
    [Segundo Parcial] RN-SaaS-01 - Límite de sucursales por plan
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Consumido por: Frontend (Admin)
    Crear una nueva sucursal (solo administradores)
    """
    # Validar límite de sucursales según plan
    suscripcion = db.query(Suscripcion).filter(
        Suscripcion.empresa_id == empresa_id,
        Suscripcion.estado == "activo"
    ).first()

    if not suscripcion:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No existe una suscripción activa para su empresa"
        )

    plan = db.query(Plan).filter(Plan.id == suscripcion.plan_id).first()
    if not plan:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Plan no encontrado"
        )

    cantidad_actual = db.query(Sucursal).filter(Sucursal.empresa_id == empresa_id).count()
    if cantidad_actual >= plan.max_sucursales:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Límite de sucursales alcanzado para su plan actual. Tu plan actual permite hasta {plan.max_sucursales}"
        )

    sucursal = Sucursal(
        nombre=datos.nombre,
        direccion=datos.direccion,
        ciudad=datos.ciudad,
        telefono=datos.telefono,
        activo=datos.activo if datos.activo is not None else True,
        empresa_id=empresa_id
    )

    db.add(sucursal)
    db.commit()
    db.refresh(sucursal)
    return sucursal



@router.put(
    "/{sucursal_id}",
    response_model=SucursalRespuesta
)
def actualizar_sucursal(
    sucursal_id: int,
    datos: SucursalActualizar,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Actualizar una sucursal (solo administradores)"""
    return branch_service.actualizar_sucursal(db, sucursal_id, datos)


@router.delete(
    "/{sucursal_id}",
    response_model=SucursalRespuesta
)
def eliminar_sucursal(
    sucursal_id: int,
    db: Session = Depends(obtener_db),
    _usuario_admin=Depends(requerir_rol("administrador"))
):
    """Desactivar una sucursal (solo administradores)"""
    return branch_service.eliminar_sucursal(db, sucursal_id)
