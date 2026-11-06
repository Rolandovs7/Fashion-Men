"""
[Segundo Parcial] CU03 - Iniciar sesión - JWT con empresa_id
[Segundo Parcial] RNF02 - Aislamiento de datos por empresa
Consumido por: Frontend (Admin/Cliente)
"""
from datetime import datetime, timezone

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt
from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.core.security import SECRET_KEY, ALGORITHM
from app.models.user import Usuario
from app.models.saas import Suscripcion

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


def obtener_db():
    """Obtener una sesión de base de datos"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def obtener_usuario_actual(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(obtener_db)
) -> Usuario:
    """Obtener el usuario autenticado a partir del token JWT"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("sub")
        if email is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token inválido"
            )
    except jwt.JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido"
        )

    usuario = db.query(Usuario).filter(Usuario.email == email).first()
    if usuario is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario no encontrado"
        )

    if not usuario.activo:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario desactivado"
        )

    return usuario


def requerir_rol(rol_requerido: str):
    """Dependencia para requerir un rol específico"""
    def _requerir_rol(usuario_actual: Usuario = Depends(obtener_usuario_actual)):
        if usuario_actual.rol != rol_requerido:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permisos para realizar esta acción"
            )
        return usuario_actual
    return _requerir_rol


def get_current_empresa_id(usuario_actual: Usuario = Depends(obtener_usuario_actual)) -> int:
    """
    [Segundo Parcial] CU03 - Aislamiento
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Extraer el empresa_id del usuario autenticado desde el contexto del token/usuario
    """
    if usuario_actual.empresa_id is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Usuario sin empresa asignada"
        )
    return usuario_actual.empresa_id


def requerir_suscripcion_vigente(
    empresa_id: int = Depends(get_current_empresa_id),
    db: Session = Depends(obtener_db),
) -> Suscripcion:
    """
    [Segundo Parcial] Desafío VI - Validar vencimiento de suscripción
    Bloquea acceso si no hay suscripción activa o si está vencida (fecha_fin < ahora).
    """
    suscripcion = (
        db.query(Suscripcion)
        .filter(Suscripcion.empresa_id == empresa_id, Suscripcion.estado == "activo")
        .order_by(Suscripcion.fecha_inicio.desc())
        .first()
    )
    if not suscripcion:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No existe una suscripción activa para su empresa",
        )

    ahora = datetime.now(timezone.utc)
    fecha_fin = suscripcion.fecha_fin
    if fecha_fin is not None:
        # Normalizar naive/aware para comparación segura
        if fecha_fin.tzinfo is None:
            fecha_fin_cmp = fecha_fin.replace(tzinfo=timezone.utc)
        else:
            fecha_fin_cmp = fecha_fin
        if fecha_fin_cmp < ahora:
            raise HTTPException(
                status_code=status.HTTP_402_PAYMENT_REQUIRED,
                detail="La suscripción de su empresa está vencida. Actualice su plan para continuar.",
            )

    return suscripcion
