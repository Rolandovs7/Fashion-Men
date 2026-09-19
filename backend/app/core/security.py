from datetime import datetime, timedelta, timezone
import os

from jose import jwt
from passlib.context import CryptContext
from dotenv import load_dotenv

load_dotenv()

# SECRET_KEY obligatoria en producción. Si falta en Render → falla al arrancar.
# En desarrollo local, si no está, se genera una aleatoria (que invalida tokens
# al reiniciar, pero es seguro para tests).
SECRET_KEY = os.getenv("SECRET_KEY")
if not SECRET_KEY:
    import secrets as _secrets
    import logging as _logging

    _entorno = os.getenv("ENVIRONMENT", "development").lower()
    if _entorno == "production":
        raise RuntimeError(
            "SECRET_KEY no está definida en producción. "
            "Configúrala en Render → Environment."
        )
    SECRET_KEY = _secrets.token_urlsafe(48)
    _logging.warning(
        "⚠️ SECRET_KEY no definida. Generando una aleatoria temporal. "
        "En producción esto es un error fatal."
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
