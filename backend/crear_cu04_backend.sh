#!/bin/bash

mkdir -p app/api/routes

cat > app/schemas/users.py <<'EOF'
from pydantic import BaseModel, ConfigDict, EmailStr


class UsuarioRespuesta(BaseModel):
    id: int
    nombre: str
    apellido: str
    email: EmailStr
    activo: bool
    rol: str

    model_config = ConfigDict(from_attributes=True)


class UsuarioActualizar(BaseModel):
    nombre: str
    apellido: str
    email: EmailStr
    activo: bool
    rol: str
EOF


cat > app/api/routes/users.py <<'EOF'
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, requerir_rol
from app.models.user import Usuario
from app.schemas.users import UsuarioRespuesta, UsuarioActualizar


router = APIRouter(
    prefix="/usuarios",
    tags=["Usuarios"]
)


@router.get(
    "",
    response_model=list[UsuarioRespuesta]
)
def listar_usuarios(
    db: Session = Depends(obtener_db),
    usuario_actual: Usuario = Depends(
        requerir_rol("administrador")
    )
):
    return db.query(Usuario).order_by(Usuario.id).all()


@router.get(
    "/{usuario_id}",
    response_model=UsuarioRespuesta
)
def obtener_usuario(
    usuario_id: int,
    db: Session = Depends(obtener_db),
    usuario_actual: Usuario = Depends(
        requerir_rol("administrador")
    )
):
    usuario = db.query(Usuario).filter(
        Usuario.id == usuario_id
    ).first()

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )

    return usuario


@router.put(
    "/{usuario_id}",
    response_model=UsuarioRespuesta
)
def actualizar_usuario(
    usuario_id: int,
    datos: UsuarioActualizar,
    db: Session = Depends(obtener_db),
    usuario_actual: Usuario = Depends(
        requerir_rol("administrador")
    )
):
    usuario = db.query(Usuario).filter(
        Usuario.id == usuario_id
    ).first()

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
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

    if datos.rol not in ["cliente", "administrador"]:
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


@router.delete(
    "/{usuario_id}"
)
def eliminar_usuario(
    usuario_id: int,
    db: Session = Depends(obtener_db),
    usuario_actual: Usuario = Depends(
        requerir_rol("administrador")
    )
):
    usuario = db.query(Usuario).filter(
        Usuario.id == usuario_id
    ).first()

    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )

    if usuario.id == usuario_actual.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No puedes eliminar tu propio usuario"
        )

    db.delete(usuario)
    db.commit()

    return {
        "mensaje": "Usuario eliminado correctamente"
    }
EOF

echo "CU04 backend creado correctamente."
