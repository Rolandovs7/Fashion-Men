from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


def _validar_email_tolerante(valor: str) -> str:
    """Valida el email permitiendo dominios reservados (.test) usados por
    los datos de demostración: `EmailStr` los rechaza, pero el panel de
    administración debe poder editar esos usuarios sin cambiar el correo."""
    from email_validator import EmailNotValidError, validate_email

    try:
        validate_email(valor, test_environment=True)
    except EmailNotValidError as exc:
        raise ValueError(str(exc)) from exc
    return valor


class UsuarioRespuesta(BaseModel):
    id: int
    nombre: str
    apellido: str
    email: str
    telefono: str | None = None
    activo: bool
    rol: str
    empresa_id: int | None = None

    model_config = ConfigDict(from_attributes=True)


class UsuarioActualizar(BaseModel):
    nombre: str
    apellido: str
    email: str = Field(..., min_length=3, max_length=150)
    telefono: str | None = None
    activo: bool
    rol: str

    @field_validator("email")
    @classmethod
    def validar_email(cls, v: str) -> str:
        return _validar_email_tolerante(v)


class UsuarioCrear(BaseModel):
    nombre: str
    apellido: str
    email: EmailStr
    telefono: str | None = None
    password: str
    rol: str = "cliente"
