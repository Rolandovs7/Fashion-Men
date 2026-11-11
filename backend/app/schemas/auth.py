from pydantic import BaseModel, ConfigDict, EmailStr, field_validator

from app.core.password_validator import mensaje_error_password


class RegistroUsuario(BaseModel):
    nombre: str
    apellido: str
    email: EmailStr
    telefono: str | None = None
    password: str
    # [Multitenant] Empresa (tienda) a la que pertenece el cliente.
    # Si no se envía se usa MenStyle por compatibilidad.
    empresa_id: int | None = None

    @field_validator("password")
    @classmethod
    def validar_password(cls, v: str) -> str:
        error = mensaje_error_password(v)
        if error:
            raise ValueError(error)
        return v


class LoginUsuario(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str


class UsuarioRespuesta(BaseModel):
    id: int
    nombre: str
    apellido: str
    email: str
    telefono: str | None = None
    activo: bool
    rol: str
    empresa_id: int | None = None
    empresa_nombre: str | None = None

    model_config = ConfigDict(from_attributes=True)


# ============================================================
# SCHEMAS DE RECUPERACIÓN DE CONTRASEÑA
# ============================================================

class SolicitarResetPassword(BaseModel):
    email: EmailStr


class ResetPassword(BaseModel):
    token: str
    password_nueva: str

    @field_validator("password_nueva")
    @classmethod
    def validar_password(cls, v: str) -> str:
        error = mensaje_error_password(v)
        if error:
            raise ValueError(error)
        return v


class MensajeRespuesta(BaseModel):
    mensaje: str