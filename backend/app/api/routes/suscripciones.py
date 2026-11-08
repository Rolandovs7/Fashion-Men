"""
[Segundo Parcial] CU01/CU02 - Suscripciones y Planes
Endpoints para consultar planes, iniciar checkout y confirmar pago (simulado).
"""
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_empresa_id, obtener_db, obtener_usuario_actual, requerir_rol
from app.models.branch import Sucursal
from app.models.saas import Empresa, Plan, Suscripcion
from app.models.user import Usuario
from app.schemas.suscripciones import (
    PlanRead,
    SuscripcionActualRead,
    CambiarPlanRequest,
    CheckoutPlanResponse,
    ConfirmarPagoRequest,
)
from app.services.email_service import enviar_correo_pago

router = APIRouter()


def _suscripcion_activa(db: Session, empresa_id: int) -> Suscripcion | None:
    return (
        db.query(Suscripcion)
        .filter(Suscripcion.empresa_id == empresa_id, Suscripcion.estado == "activo")
        .order_by(Suscripcion.fecha_inicio.desc())
        .first()
    )


def _validar_cambio_plan(db: Session, empresa_id: int, plan_id: int) -> tuple[Suscripcion, Plan]:
    """[Segundo Parcial] CU02 - Validación común para iniciar checkout/confirmar pago."""
    suscripcion_actual = _suscripcion_activa(db, empresa_id)
    if not suscripcion_actual:
        raise HTTPException(status_code=404, detail="No existe una suscripción activa para su empresa")

    if suscripcion_actual.plan_id == plan_id:
        raise HTTPException(status_code=400, detail="Ya tienes este plan activo")

    nuevo_plan = db.query(Plan).filter(Plan.id == plan_id).first()
    if not nuevo_plan:
        raise HTTPException(status_code=404, detail="El plan seleccionado no existe")

    cantidad_sucursales = db.query(Sucursal).filter(Sucursal.empresa_id == empresa_id).count()
    if cantidad_sucursales > nuevo_plan.max_sucursales:
        raise HTTPException(
            status_code=400,
            detail=(
                f"No puedes cambiar al plan {nuevo_plan.nombre}: tienes {cantidad_sucursales} sucursal(es) "
                f"y el plan permite hasta {nuevo_plan.max_sucursales}. Elimina sucursales primero."
            ),
        )
    return suscripcion_actual, nuevo_plan


def _aplicar_cambio_plan(db: Session, empresa_id: int, suscripcion_actual: Suscripcion, nuevo_plan: Plan) -> Suscripcion:
    """[Segundo Parcial] CU02 - Aplica cambio real en BD tras pago confirmado."""
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
    return nueva


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
    suscripcion = _suscripcion_activa(db, empresa_id)
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


@router.put("/cambiar-plan", response_model=CheckoutPlanResponse)
def iniciar_checkout_cambiar_plan(
    datos: CambiarPlanRequest,
    db: Session = Depends(obtener_db),
    _admin: Usuario = Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id),
):
    """
    [Segundo Parcial] CU02 - Suscripción (cobro automático simulado)
    Inicia checkout (Stripe simulado): valida límites y devuelve checkout_url ficticia.
    No modifica la suscripción hasta confirmar el pago.
    """
    _suscripcion_actual, nuevo_plan = _validar_cambio_plan(db, empresa_id, datos.plan_id)
    checkout_url = f"https://checkout.stripe.com/pay/cs_test_sim_{empresa_id}_{nuevo_plan.id}_{int(datetime.now(timezone.utc).timestamp())}"
    return CheckoutPlanResponse(
        checkout_url=checkout_url,
        plan_id=nuevo_plan.id,
        plan_nombre=nuevo_plan.nombre,
        monto=nuevo_plan.precio_mensual,
    )


@router.post("/confirmar-pago", response_model=SuscripcionActualRead)
def confirmar_pago_plan(
    datos: ConfirmarPagoRequest,
    db: Session = Depends(obtener_db),
    _admin: Usuario = Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id),
):
    """
    [Segundo Parcial] CU02 - Suscripción
    Simula confirmación de pago Stripe (payment_status='success') y aplica el cambio real:
    inactiva el plan anterior y crea la nueva suscripción (1 mes).
    """
    if (datos.payment_status or "").lower() != "success":
        raise HTTPException(status_code=400, detail="El pago no fue aprobado (simulación).")

    suscripcion_actual, nuevo_plan = _validar_cambio_plan(db, empresa_id, datos.plan_id)
    nueva = _aplicar_cambio_plan(db, empresa_id, suscripcion_actual, nuevo_plan)

    # [SaaS] Correo simulado de confirmación de pago/cambio de plan
    try:
        empresa = db.query(Empresa).filter(Empresa.id == empresa_id).first()
        nombre_empresa = empresa.nombre if empresa else f"Empresa #{empresa_id}"
        destinatario = getattr(_admin, "email", None)
        if destinatario:
            enviar_correo_pago(destinatario, nombre_empresa, nuevo_plan.nombre, nuevo_plan.precio_mensual)
    except Exception:
        # No interrumpir la confirmación de pago por un fallo en correo simulado
        pass

    return SuscripcionActualRead(
        id=nueva.id,
        empresa_id=nueva.empresa_id,
        plan=PlanRead.model_validate(nuevo_plan),
        fecha_inicio=nueva.fecha_inicio,
        fecha_fin=nueva.fecha_fin,
        estado=nueva.estado,
    )
