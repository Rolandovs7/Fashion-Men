"""
Limiter global con soporte para proxies (Render).

Render pone la IP real del cliente en el header X-Forwarded-For.
Si no está, cae al default de slowapi (request.client.host).
"""
from slowapi import Limiter
from starlette.requests import Request


def obtener_ip_real(request: Request) -> str:
    """
    Extrae la IP del cliente considerando proxies.

    - Si existe X-Forwarded-For, toma la primera IP (la del cliente).
    - Si no, usa request.client.host.
    """
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        # X-Forwarded-For puede tener varias IPs separadas por coma.
        # La primera es la del cliente original.
        return forwarded.split(",")[0].strip()

    real_ip = request.headers.get("X-Real-IP")
    if real_ip:
        return real_ip.strip()

    if request.client:
        return request.client.host

    return "unknown"


limiter = Limiter(
    key_func=obtener_ip_real,
    default_limits=["200/minute"],
)