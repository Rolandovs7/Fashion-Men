from datetime import datetime

from pydantic import BaseModel, EmailStr, Field


class EmpresaCrearRequest(BaseModel):
    """Registro de nueva empresa (tenant) con plan inicial. Requiere rol superadmin."""
    nombre_empresa: str = Field(..., min_length=2, max_length=150)
    plan_id: int = Field(..., gt=0)
    nit: str | None = Field(None, min_length=5, max_length=50)
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


class EmpresaEstadoRequest(BaseModel):
    """Cambio de estado (activo/inactivo) de un tenant. Solo superadmin."""
    activo: bool


class EmpresaListadoRead(BaseModel):
    """Listado de tenants para SuperAdmin."""
    id: int
    nombre: str
    nit: str | None = None
    fecha_registro: datetime | None = None
    plan_actual: str | None = None
    activo: bool = True


class EmpresaUsuarioRead(BaseModel):
    """Usuario/cliente de una empresa (panel de administración)."""
    id: int
    nombre: str
    apellido: str
    nombre_completo: str
    email: str
    telefono: str | None = None
    fecha_registro: datetime | None = None
    activo: bool = True
    rol: str = "cliente"