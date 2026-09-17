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


class UsuarioCrear(BaseModel):
    nombre: str
    apellido: str
    email: EmailStr
    password: str
    rol: str = "cliente"
