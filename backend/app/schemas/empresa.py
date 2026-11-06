from pydantic import BaseModel, EmailStr, Field


class EmpresaCrearRequest(BaseModel):
    """Registro de nueva empresa (tenant) con plan inicial. Requiere rol superadmin."""
    nombre_empresa: str = Field(..., min_length=2, max_length=150)
    plan_id: int = Field(..., gt=0)
    # Opcional: crear usuario administrador inicial
    admin_nombre: str | None = Field(None, min_length=1, max_length=100)
    admin_apellido: str | None = Field(None, min_length=1, max_length=100)
    admin_email: EmailStr | None = None
    admin_password: str | None = Field(None, min_length=6, max_length=128)


class EmpresaCrearResponse(BaseModel):
    empresa_id: int
    empresa_nombre: str
    plan_id: int
    plan_nombre: str
    suscripcion_id: int
    admin_usuario_id: int | None = None
    mensaje: str