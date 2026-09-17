from pydantic import BaseModel, ConfigDict, EmailStr


class RegistroUsuario(BaseModel):
    nombre: str
    apellido: str
    email: EmailStr
    password: str


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
    email: EmailStr
    activo: bool
    rol: str

    model_config = ConfigDict(from_attributes=True)