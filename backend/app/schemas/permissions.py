from pydantic import BaseModel


class PermisoRespuesta(BaseModel):
    id: int
    nombre: str
    descripcion: str
    activo: bool


class AsignarPermiso(BaseModel):
    rol: str
    permiso_id: int
