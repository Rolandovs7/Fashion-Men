"""
[Segundo Parcial] CU01/CU02 - Suscripciones y Planes
Endpoints para consultar planes disponibles y suscripción actual.
"""
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_empresa_id, obtener_db, obtener_usuario_actual, requerir_rol
from app.models.branch import Sucursal
from app.models.saas import Plan, Suscripcion
from app.models.user import Usuario
from app.schemas.suscripciones import PlanRead, SuscripcionActualRead, CambiarPlanRequest

router = APIRouter()


@router.get("/planes", response_model=list[PlanRead])
def listar_planes(db: Session = Depends(obtener_db)):
    """Lista los planes disponibles (tabla de precios)."""
    planes = db.query(Plan).order_by(Plan.precio_mensual.asc(), Plan.id.asc()).all()
    return planes


@router.get("/mi-suscripcion", response_model=SuscripcionActualRead)
def obtener_mi_suscripcion(
    db: Session = Depends(obtener_db),
    usuario: Usuario = Depends(obtener_usuario_actual),
    empresa_id: int = Depends(get_current_empresa_id),
):
    """Obtiene la suscripción activa de la empresa actual."""
    suscripcion = (
        db.query(Suscripcion)
        .filter(Suscripcion.empresa_id == empresa_id, Suscripcion.estado == "activo")
        .order_by(Suscripcion.fecha_inicio.desc())
        .first()
    )
    if not suscripcion:
        raise HTTPException(status_code=404, detail="No existe una suscripción activa para su empresa")

    plan = db.query(Plan).filter(Plan.id == suscripcion.plan_id).first()
    if not plan:
        raise HTTPException(status_code=404, detail="El plan asociado no es válido")

    return SuscripcionActualRead(
        id=suscripcion.id,
        empresa_id=suscripcion.empresa_id,
        plan=PlanRead.model_validate(plan),
        fecha_inicio=suscripcion.fecha_inicio,
        fecha_fin=suscripcion.fecha_fin,
        estado=suscripcion.estado,
    )


@router.put("/cambiar-plan", response_model=SuscripcionActualRead)
def cambiar_plan(
    datos: CambiarPlanRequest,
    db: Session = Depends(obtener_db),
    _admin: Usuario = Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id),
):
    """Cambia el plan de la suscripción activa (real). Valida límites al bajar de plan."""
    suscripcion_actual = (
        db.query(Suscripcion)
        .filter(Suscripcion.empresa_id == empresa_id, Suscripcion.estado == "activo")
        .order_by(Suscripcion.fecha_inicio.desc())
        .first()
    )
    if not suscripcion_actual:
        raise HTTPException(status_code=404, detail="No existe una suscripción activa para su empresa")

    if suscripcion_actual.plan_id == datos.plan_id:
        plan = db.query(Plan).filter(Plan.id == datos.plan_id).first()
        return SuscripcionActualRead(
            id=suscripcion_actual.id,
            empresa_id=suscripcion_actual.empresa_id,
            plan=PlanRead.model_validate(plan),
            fecha_inicio=suscripcion_actual.fecha_inicio,
            fecha_fin=suscripcion_actual.fecha_fin,
            estado=suscripcion_actual.estado,
        )

    nuevo_plan = db.query(Plan).filter(Plan.id == datos.plan_id).first()
    if not nuevo_plan:
        raise HTTPException(status_code=404, detail="El plan seleccionado no existe")

    # Validación de límites al bajar/cambiar: no exceder max_sucursales del nuevo plan
    cantidad_sucursales = db.query(Sucursal).filter(Sucursal.empresa_id == empresa_id).count()
    if cantidad_sucursales > nuevo_plan.max_sucursales:
        raise HTTPException(
            status_code=400,
            detail=(
                f"No puedes cambiar al plan {nuevo_plan.nombre}: tienes {cantidad_sucursales} sucursal(es) "
                f"y el plan permite hasta {nuevo_plan.max_sucursales}. Elimina sucursales primero."
            ),
        )

    ahora = datetime.now(timezone.utc)
    suscripcion_actual.estado = "inactivo"
    suscripcion_actual.fecha_fin = ahora

    nueva = Suscripcion(
        empresa_id=empresa_id,
        plan_id=nuevo_plan.id,
        fecha_inicio=ahora,
        fecha_fin=ahora + timedelta(days=30),
        estado="activo",
    )
    db.add(nueva)
    db.commit()
    db.refresh(nueva)

    return SuscripcionActualRead(
        id=nueva.id,
        empresa_id=nueva.empresa_id,
        plan=PlanRead.model_validate(nuevo_plan),
        fecha_inicio=nueva.fecha_inicio,
        fecha_fin=nueva.fecha_fin,
        estado=nueva.estado,
    )
