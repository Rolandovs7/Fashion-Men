from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

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
from app.models.user import Usuario
from app.schemas.auth import (
    RegistroUsuario,
    Token,
    UsuarioRespuesta
)

router = APIRouter(
    tags=["Autenticación"]
)

# ============================================================
# TRAZABILIDAD MENSTYLE
# CU: CU01 - Administrar Inicio de Sesión
# CU: CU02 - Administrar Cierre de Sesión (el logout es stateless:
#     no hay endpoint de logout; el cliente descarta el token JWT)
# CU: CU03 - Registrar Usuario
# RF: RF01 - Registrar clientes
# ENDPOINT: POST /api/auth/registro, POST /api/auth/login, GET /api/auth/me
# CAPA: Backend FastAPI
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


@router.post("/login", response_model=Token)
def login_usuario(
    datos: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(obtener_db)
):
    """Iniciar sesión"""

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