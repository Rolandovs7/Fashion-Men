from datetime import datetime, timedelta, timezone
import os

from jose import jwt
from passlib.context import CryptContext
from dotenv import load_dotenv

load_dotenv()

SECRET_KEY = os.getenv(
    "SECRET_KEY",
    "menstyle-clave-secreta-cambiar-en-produccion"
)

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto"
)


def verificar_password(password: str, password_hash: str) -> bool:
    return pwd_context.verify(password, password_hash)


def obtener_password_hash(password: str) -> str:
    return pwd_context.hash(password)


def crear_access_token(data: dict) -> str:
    datos = data.copy()

    expiracion = datetime.now(timezone.utc) + timedelta(
        minutes=ACCESS_TOKEN_EXPIRE_MINUTES
    )

    datos.update({"exp": expiracion})

    return jwt.encode(
        datos,
        SECRET_KEY,
        algorithm=ALGORITHM
    )
