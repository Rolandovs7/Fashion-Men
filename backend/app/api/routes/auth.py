import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.core.limiter import limiter
from app.core.dependencies import (
    obtener_db,
    obtener_usuario_actual,
    requerir_rol
)
from app.core.security import (
    obtener_password_hash,
    verificar_password,
    crear_access_token
)
from app.core.password_validator import mensaje_error_password
from app.models.user import Usuario
from app.models.password_reset_token import PasswordResetToken
from app.services.email_service import enviar_email_reset_password
from app.schemas.auth import (
    RegistroUsuario,
    Token,
    UsuarioRespuesta,
    SolicitarResetPassword,
    ResetPassword,
    MensajeRespuesta,
)

router = APIRouter(
    tags=["Autenticación"]
)

# ============================================================
# TRAZABILIDAD MENSTYLE
# CU: CU01 - Administrar Inicio de Sesión
# CU: CU02 - Administrar Cierre de Sesión (stateless)
# CU: CU03 - Registrar Usuario
# CU: CU04 - Recuperar Contraseña
# RF: RF01 - Registrar clientes
# RF: RF02 - Recuperar contraseña vía email
# CAPA: Backend FastAPI
# ============================================================


# ============================================================
# REGISTRO
# ============================================================

@router.post(
    "/registro",
    response_model=UsuarioRespuesta,
    status_code=status.HTTP_201_CREATED
)
def registro_usuario(
    datos: RegistroUsuario,
    db: Session = Depends(obtener_db)
):
    """Registrar un nuevo usuario"""

    usuario_existente = db.query(Usuario).filter(
        Usuario.email == datos.email
    ).first()

    if usuario_existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El email ya está registrado"
        )

    nuevo_usuario = Usuario(
        nombre=datos.nombre,
        apellido=datos.apellido,
        email=datos.email,
        password_hash=obtener_password_hash(datos.password),
        rol="cliente",
        activo=True
    )

    db.add(nuevo_usuario)
    db.commit()
    db.refresh(nuevo_usuario)

    return nuevo_usuario


# ============================================================
# LOGIN
# ============================================================

@router.post("/login", response_model=Token)
@limiter.limit("5/minute")
def login_usuario(
    request: Request,
    datos: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(obtener_db)
):
    """Iniciar sesión (limitado a 5 intentos por minuto por IP)"""

    usuario = db.query(Usuario).filter(
        Usuario.email == datos.username
    ).first()

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email o contraseña incorrectos"
        )

    if not verificar_password(
        datos.password,
        usuario.password_hash
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email o contraseña incorrectos"
        )

    if not usuario.activo:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario desactivado"
        )

    token_data = {
        "sub": usuario.email,
        "rol": usuario.rol
    }

    access_token = crear_access_token(token_data)

    return {
        "access_token": access_token,
        "token_type": "bearer"
    }


# ============================================================
# USUARIO ACTUAL
# ============================================================

@router.get("/me", response_model=UsuarioRespuesta)
def obtener_usuario_actual_endpoint(
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
    """Obtener el usuario autenticado"""

    return usuario_actual


@router.get("/admin")
def ruta_admin(
    usuario_actual: Usuario = Depends(
        requerir_rol("administrador")
    )
):
    """Ruta solo para administradores"""

    return {
        "mensaje": "Bienvenido administrador"
    }


# ============================================================
# RECUPERACIÓN DE CONTRASEÑA
# CU: CU04 - Recuperar Contraseña
# RF: RF02 - Recuperar contraseña vía email
# ============================================================

@router.post("/forgot-password", response_model=MensajeRespuesta)
def solicitar_reset_password(
    datos: SolicitarResetPassword,
    db: Session = Depends(obtener_db)
):
    """
    Solicita un link de recuperación de contraseña.

    - Genera un token UUID válido por 30 minutos.
    - Envía email con el link.
    - Por seguridad, responde igual si el email existe o no
      (evita enumeración de usuarios).
    """
    usuario = db.query(Usuario).filter(
        Usuario.email == datos.email
    ).first()

    # Respuesta genérica (no revela si el email existe)
    respuesta_generica = {
        "mensaje": "Si el email está registrado, recibirás un link de recuperación."
    }

    if not usuario:
        return respuesta_generica

    if not usuario.activo:
        return respuesta_generica

    # Invalidar tokens previos no usados de este usuario
    db.query(PasswordResetToken).filter(
        PasswordResetToken.usuario_id == usuario.id,
        PasswordResetToken.usado == False  # noqa: E712
    ).update({"usado": True})

    # Generar nuevo token (URL-safe, ~64 caracteres)
    token_str = secrets.token_urlsafe(48)
    expira = datetime.now(timezone.utc) + timedelta(minutes=30)

    nuevo_token = PasswordResetToken(
        usuario_id=usuario.id,
        token=token_str,
        expira_en=expira,
        usado=False
    )
    db.add(nuevo_token)
    db.commit()

    # Enviar email (no bloquea si falla)
    enviar_email_reset_password(
        destinatario=usuario.email,
        nombre_usuario=usuario.nombre,
        token=token_str
    )

    return respuesta_generica


@router.post("/reset-password", response_model=MensajeRespuesta)
def reset_password(
    datos: ResetPassword,
    db: Session = Depends(obtener_db)
):
    """
    Cambia la contraseña usando el token del email.

    - Valida token (existe, no usado, no expirado).
    - Valida fuerza de la contraseña.
    - Actualiza password_hash.
    - Marca el token como usado.
    """
    # Buscar token
    reset_token = db.query(PasswordResetToken).filter(
        PasswordResetToken.token == datos.token
    ).first()

    if not reset_token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Token inválido"
        )

    if reset_token.usado:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Este token ya fue usado"
        )

    # Verificar expiración (compatibilidad con tz aware/naive)
    expira = reset_token.expira_en
    if expira.tzinfo is None:
        expira = expira.replace(tzinfo=timezone.utc)

    if expira < datetime.now(timezone.utc):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El token expiró. Solicitá uno nuevo."
        )

    # Verificar usuario
    usuario = db.query(Usuario).filter(
        Usuario.id == reset_token.usuario_id
    ).first()

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Usuario no encontrado"
        )

    if not usuario.activo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Usuario desactivado"
        )

    # Validar contraseña (redundante, el schema ya valida)
    error = mensaje_error_password(datos.password_nueva)
    if error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error
        )

    # Actualizar contraseña + marcar token como usado
    usuario.password_hash = obtener_password_hash(datos.password_nueva)
    reset_token.usado = True
    db.commit()

    return {
        "mensaje": "Contraseña actualizada correctamente. Ya podés iniciar sesión."
    }