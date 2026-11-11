"""
[Segundo Parcial] Desafío VI - Gestión de empresas (tenants) - SuperAdmin
Permite registrar nuevas empresas y asignarles un plan inicial.
"""
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol
from app.core.security import obtener_password_hash
from app.models.saas import Empresa, Plan, Suscripcion
from app.models.user import Usuario
from app.schemas.empresa import (
    EmpresaCrearRequest,
    EmpresaCrearResponse,
    EmpresaEstadoRequest,
    EmpresaListadoRead,
)
from app.services.email_service import enviar_correo_bienvenida

router = APIRouter()


@router.get("", response_model=list[EmpresaListadoRead])
def listar_empresas(
    db: Session = Depends(obtener_db),
    _superadmin: Usuario = Depends(requerir_rol("superadmin")),
):
    """Lista todas las empresas (tenants) con su plan actual. Solo superadmin."""
    empresas = db.query(Empresa).order_by(Empresa.id.asc()).all()
    resultado: list[EmpresaListadoRead] = []
    for emp in empresas:
        sus = (
            db.query(Suscripcion)
            .filter(Suscripcion.empresa_id == emp.id, Suscripcion.estado == "activo")
            .order_by(Suscripcion.fecha_inicio.desc())
            .first()
        )
        if sus is None:
            sus = (
                db.query(Suscripcion)
                .filter(Suscripcion.empresa_id == emp.id)
                .order_by(Suscripcion.fecha_inicio.desc())
                .first()
            )
        plan_nombre = None
        if sus is not None:
            plan = db.query(Plan).filter(Plan.id == sus.plan_id).first()
            plan_nombre = plan.nombre if plan else None
        resultado.append(
            EmpresaListadoRead(
                id=emp.id,
                nombre=emp.nombre,
                nit=getattr(emp, "nit", None),
                fecha_registro=getattr(emp, "fecha_registro", None),
                plan_actual=plan_nombre,
                activo=bool(getattr(emp, "activo", True)),
            )
        )
    return resultado


@router.post("", response_model=EmpresaCrearResponse, status_code=status.HTTP_201_CREATED)
def crear_empresa(
    datos: EmpresaCrearRequest,
    db: Session = Depends(obtener_db),
    _superadmin: Usuario = Depends(requerir_rol("superadmin")),
):
    """Registra una nueva empresa (tenant) y le asigna un plan inicial. Solo superadmin."""
    existe = db.query(Empresa).filter(Empresa.nombre == datos.nombre_empresa).first()
    if existe:
        raise HTTPException(status_code=400, detail="Ya existe una empresa con ese nombre")

    plan = db.query(Plan).filter(Plan.id == datos.plan_id).first()
    if not plan:
        raise HTTPException(status_code=404, detail="El plan indicado no existe")

    admin_usuario_id = None
    if datos.admin_email:
        if db.query(Usuario).filter(Usuario.email == datos.admin_email).first():
            raise HTTPException(status_code=400, detail="El email del administrador ya está registrado")
        if not datos.admin_password or not datos.admin_nombre or not datos.admin_apellido:
            raise HTTPException(status_code=400, detail="Para crear el usuario admin inicial indique nombre, apellido, email y contraseña")

    empresa = Empresa(nombre=datos.nombre_empresa, nit=datos.nit, activo=True)
    db.add(empresa)
    db.flush()

    ahora = datetime.now(timezone.utc)
    suscripcion = Suscripcion(
        empresa_id=empresa.id,
        plan_id=plan.id,
        fecha_inicio=ahora,
        fecha_fin=ahora + timedelta(days=30),
        estado="activo",
    )
    db.add(suscripcion)
    db.flush()

    if datos.admin_email:
        admin = Usuario(
            nombre=datos.admin_nombre,
            apellido=datos.admin_apellido,
            email=datos.admin_email,
            password_hash=obtener_password_hash(datos.admin_password),
            rol="administrador",
            activo=True,
            empresa_id=empresa.id,
        )
        db.add(admin)
        db.flush()
        admin_usuario_id = admin.id

    db.commit()

    # [SaaS] Correo simulado de bienvenida (a admin inicial si se proporcionó)
    try:
        if datos.admin_email:
            enviar_correo_bienvenida(datos.admin_email, empresa.nombre, plan.nombre)
    except Exception:
        # No interrumpir el alta de empresa por un fallo en correo simulado
        pass

    return EmpresaCrearResponse(
        empresa_id=empresa.id,
        empresa_nombre=empresa.nombre,
        plan_id=plan.id,
        plan_nombre=plan.nombre,
        suscripcion_id=suscripcion.id,
        admin_usuario_id=admin_usuario_id,
        mensaje="Empresa registrada correctamente con plan inicial.",
    )


@router.patch(
    "/{empresa_id}/estado",
    response_model=EmpresaListadoRead,
)
def cambiar_estado_empresa(
    empresa_id: int,
    datos: EmpresaEstadoRequest,
    db: Session = Depends(obtener_db),
    _superadmin: Usuario = Depends(requerir_rol("superadmin")),
):
    """
    [SaaS] Activa/desactiva un tenant. Solo superadmin.
    Una empresa desactivada no puede iniciar sesión ni consumir la API
    (ver auth.login y dependencies.obtener_usuario_actual).
    """
    empresa = db.query(Empresa).filter(Empresa.id == empresa_id).first()
    if not empresa:
        raise HTTPException(status_code=404, detail="La empresa indicada no existe")

    empresa.activo = datos.activo
    db.commit()
    db.refresh(empresa)

    # Reutiliza la misma lógica de listado para devolver plan actual
    sus = (
        db.query(Suscripcion)
        .filter(Suscripcion.empresa_id == empresa.id, Suscripcion.estado == "activo")
        .order_by(Suscripcion.fecha_inicio.desc())
        .first()
    )
    plan_nombre = None
    if sus is not None:
        plan = db.query(Plan).filter(Plan.id == sus.plan_id).first()
        plan_nombre = plan.nombre if plan else None

    return EmpresaListadoRead(
        id=empresa.id,
        nombre=empresa.nombre,
        nit=getattr(empresa, "nit", None),
        fecha_registro=getattr(empresa, "fecha_registro", None),
        plan_actual=plan_nombre,
        activo=bool(empresa.activo),
    )
