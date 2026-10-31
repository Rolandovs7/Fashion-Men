"""
[Segundo Parcial] CU04 - Gestionar usuarios y roles
[Segundo Parcial] RNF02 - Aislamiento de datos por empresa
[Segundo Parcial] RF01 - Gestión Multitenant y Empresas
Consumido por: Frontend (Admin)
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol, get_current_empresa_id, obtener_usuario_actual
from app.core.security import obtener_password_hash
from app.models.user import Usuario
from app.schemas.users import UsuarioRespuesta, UsuarioActualizar, UsuarioCrear
from app.services import role_service

router = APIRouter(
    prefix="/usuarios",
    tags=["Usuarios"]
)

# ============================================================
# TRAZABILIDAD MENSTYLE
# CU: CU04 - Gestionar Usuarios
# RF: RF02 - Gestionar usuarios y roles
# ENDPOINT: GET/POST /api/usuarios, PUT/DELETE /api/usuarios/{id}
# CAPA: Backend FastAPI
# Nota: DELETE es eliminación real (no hay campo "activo" en Usuario
# para soft-delete; "desactivar" se hace vía PUT con activo=false).
# ============================================================


@router.get("", response_model=list[UsuarioRespuesta])
def listar_usuarios(
    db: Session = Depends(obtener_db),
    usuario_actual: Usuario = Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU04 - Gestionar usuarios y roles
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Listar usuarios de la empresa
    """
    return db.query(Usuario).filter(Usuario.empresa_id == empresa_id).order_by(Usuario.id).all()


@router.post("", response_model=UsuarioRespuesta, status_code=status.HTTP_201_CREATED)
def crear_usuario(
    datos: UsuarioCrear,
    db: Session = Depends(obtener_db),
    usuario_actual: Usuario = Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id)
):
    """
    [Segundo Parcial] CU04 - Gestionar usuarios y roles
    [Segundo Parcial] RNF02 - Aislamiento de datos por empresa
    Consumido por: Frontend (Admin)
    Crear un usuario directamente desde el panel de administración (asigna empresa_id del usuario logueado)
    """

    usuario_existente = db.query(Usuario).filter(
        Usuario.email == datos.email
    ).first()

    if usuario_existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El email ya está registrado"
        )

    if datos.rol not in role_service.nombres_roles_activos(db):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rol inválido"
        )

    nuevo_usuario = Usuario(
        nombre=datos.nombre,
        apellido=datos.apellido,
        email=datos.email,
        password_hash=obtener_password_hash(datos.password),
        rol=datos.rol,
        activo=True,
        empresa_id=empresa_id
    )

    db.add(nuevo_usuario)
    db.commit()
    db.refresh(nuevo_usuario)

    return nuevo_usuario




@router.get("/{usuario_id}", response_model=UsuarioRespuesta)
def obtener_usuario(
    usuario_id: int,
    db: Session = Depends(obtener_db),
    usuario_actual: Usuario = Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id)
):
    usuario = db.query(Usuario).filter(
        Usuario.id == usuario_id
    ).first()

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )

    if usuario.empresa_id != empresa_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes acceso a este usuario"
        )

    return usuario


@router.put("/{usuario_id}", response_model=UsuarioRespuesta)
def actualizar_usuario(
    usuario_id: int,
    datos: UsuarioActualizar,
    db: Session = Depends(obtener_db),
    usuario_actual: Usuario = Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id)
):
    usuario = db.query(Usuario).filter(
        Usuario.id == usuario_id
    ).first()

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )

    if usuario.empresa_id != empresa_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes acceso a este usuario"
        )

    email_existente = db.query(Usuario).filter(
        Usuario.email == datos.email,
        Usuario.id != usuario_id
    ).first()

    if email_existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El email ya está registrado"
        )

    if datos.rol not in role_service.nombres_roles_activos(db):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rol inválido"
        )

    usuario.nombre = datos.nombre
    usuario.apellido = datos.apellido
    usuario.email = datos.email
    usuario.activo = datos.activo
    usuario.rol = datos.rol

    db.commit()
    db.refresh(usuario)

    return usuario


@router.delete("/{usuario_id}")
def eliminar_usuario(
    usuario_id: int,
    db: Session = Depends(obtener_db),
    usuario_actual: Usuario = Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id)
):
    usuario = db.query(Usuario).filter(
        Usuario.id == usuario_id
    ).first()

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )

    if usuario.empresa_id != empresa_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes acceso a este usuario"
        )

    if usuario.id == usuario_actual.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No puedes eliminar tu propio usuario"
        )

    db.delete(usuario)
    db.commit()

    return {"mensaje": "Usuario eliminado correctamente"}
