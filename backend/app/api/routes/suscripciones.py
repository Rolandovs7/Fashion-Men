"""
[Segundo Parcial] CU01/CU02 - Suscripciones y Planes
Endpoints para consultar planes disponibles y suscripción actual.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_empresa_id, obtener_db, obtener_usuario_actual
from app.models.saas import Plan, Suscripcion
from app.models.user import Usuario
from app.schemas.suscripciones import PlanRead, SuscripcionActualRead

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
