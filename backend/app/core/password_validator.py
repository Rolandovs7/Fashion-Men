"""
Validador de contraseñas fuertes para MenStyle.

Reglas:
- Mínimo 8 caracteres
- Al menos 1 mayúscula (A-Z)
- Al menos 1 minúscula (a-z)
- Al menos 1 número (0-9)
- Al menos 1 carácter especial (!@#$%^&*()_+-=[]{}|;:,.<>?)

El mensaje de error devuelve TODAS las reglas incumplidas a la vez
para que el usuario pueda corregir todo de una.
"""
import re


REGLAS = {
    "longitud": (8, "Mínimo 8 caracteres"),
    "mayuscula": (r"[A-Z]", "Al menos 1 mayúscula (A-Z)"),
    "minuscula": (r"[a-z]", "Al menos 1 minúscula (a-z)"),
    "numero": (r"[0-9]", "Al menos 1 número (0-9)"),
    "simbolo": (
        r"[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]",
        "Al menos 1 carácter especial (!@#$%^&*()_+-=[]{}|;:,.<>?)"
    ),
}


def validar_password_fuerte(password: str) -> tuple[bool, list[str]]:
    """
    Valida una contraseña contra las reglas de MenStyle.

    Args:
        password: contraseña en texto plano.

    Returns:
        (es_valida, lista_de_errores)
        - es_valida: True si cumple TODAS las reglas.
        - lista_de_errores: lista de strings con las reglas incumplidas.
    """
    if not password:
        return False, ["La contraseña no puede estar vacía"]

    errores: list[str] = []

    # Longitud
    min_len, msg_len = REGLAS["longitud"]
    if len(password) < min_len:
        errores.append(f"{msg_len} (actual: {len(password)})")

    # Regex
    for clave in ("mayuscula", "minuscula", "numero", "simbolo"):
        patron, msg = REGLAS[clave]
        if not re.search(patron, password):
            errores.append(msg)

    return len(errores) == 0, errores


def mensaje_error_password(password: str) -> str | None:
    """
    Devuelve un mensaje único con todas las reglas incumplidas,
    o None si la contraseña es válida.
    """
    es_valida, errores = validar_password_fuerte(password)
    if es_valida:
        return None
    return "La contraseña no cumple las siguientes reglas: " + "; ".join(errores)