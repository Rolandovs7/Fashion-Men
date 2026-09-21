"""
Servicio de envío de emails vía SMTP (Gmail).

Uso:
    from app.services.email_service import enviar_email_reset_password

    exito = enviar_email_reset_password(
        destinatario="usuario@gmail.com",
        nombre_usuario="Juan",
        token="abc-123-xyz"
    )

Configuración (.env o variables de entorno):
    SMTP_HOST          smtp.gmail.com
    SMTP_PORT          587
    SMTP_USER          tu-correo@gmail.com
    SMTP_PASSWORD      app-password-de-gmail (SIN espacios)
    SMTP_FROM_NAME     MenStyle
    FRONTEND_URL       http://localhost:4200  (o https://menstyle-web-0de9.onrender.com)
"""
import os
import smtplib
import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.utils import formataddr

logger = logging.getLogger(__name__)

# Configuración SMTP
SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "").replace(" ", "")  # quitar espacios
SMTP_FROM_NAME = os.getenv("SMTP_FROM_NAME", "MenStyle")
FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:4200").rstrip("/")


def _smtp_configurado() -> bool:
    """Verifica si las credenciales SMTP están configuradas."""
    return bool(SMTP_USER and SMTP_PASSWORD)


def _html_reset_password(nombre: str, token: str) -> str:
    """Genera el HTML del email de recuperación."""
    link = f"{FRONTEND_URL}/reset-password?token={token}"
    return f"""<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <style>
    body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
           background: #f5f5f5; margin: 0; padding: 20px; }}
    .container {{ max-width: 600px; margin: 0 auto; background: white;
                 border-radius: 16px; padding: 40px 32px; box-shadow: 0 2px 8px rgba(0,0,0,0.05); }}
    .logo {{ font-size: 28px; font-weight: 900; letter-spacing: 3px;
            color: #000; text-align: center; margin-bottom: 8px; }}
    .subtitle {{ text-align: center; color: #888; font-size: 13px; margin-bottom: 32px; }}
    h1 {{ font-size: 22px; color: #111; margin: 0 0 16px 0; }}
    p {{ color: #444; line-height: 1.6; font-size: 15px; margin: 12px 0; }}
    .btn {{ display: inline-block; background: #000; color: #fff !important;
           padding: 14px 32px; border-radius: 12px; text-decoration: none;
           font-weight: bold; font-size: 15px; margin: 24px 0; }}
    .link {{ background: #f5f5f5; padding: 12px; border-radius: 8px;
            font-family: monospace; font-size: 12px; color: #666;
            word-break: break-all; margin: 16px 0; }}
    .footer {{ color: #999; font-size: 12px; text-align: center;
              margin-top: 32px; padding-top: 24px; border-top: 1px solid #eee; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">MENSTYLE</div>
    <div class="subtitle">Plataforma E-Commerce • FashionStore</div>

    <h1>Hola {nombre},</h1>

    <p>Recibimos una solicitud para restablecer la contraseña de tu cuenta.</p>

    <p>Hacé click en el botón para crear una nueva contraseña:</p>

    <p style="text-align: center;">
      <a href="{link}" class="btn">Restablecer contraseña</a>
    </p>

    <p>O copiá y pegá este enlace en tu navegador:</p>
    <div class="link">{link}</div>

    <p><strong>Este enlace expira en 30 minutos.</strong></p>

    <p>Si no solicitaste este cambio, ignorá este mensaje. Tu contraseña sigue siendo la misma.</p>

    <div class="footer">
      © 2026 MenStyle · Sistemas II · U.A.G.R.M.<br>
      No respondas a este correo.
    </div>
  </div>
</body>
</html>"""


def enviar_email_reset_password(
    destinatario: str,
    nombre_usuario: str,
    token: str,
) -> bool:
    """
    Envía el email con el link de recuperación de contraseña.

    Args:
        destinatario: email del usuario.
        nombre_usuario: nombre para personalizar el saludo.
        token: token UUID generado.

    Returns:
        True si se envió, False si hubo error o no está configurado.
    """
    if not _smtp_configurado():
        logger.warning(
            "SMTP no configurado. No se envió email a %s. Token: %s",
            destinatario, token
        )
        # Imprimimos el link en consola para poder probar sin SMTP
        link = f"{FRONTEND_URL}/reset-password?token={token}"
        print(f"\n📧 [MODO DEV] Link de reset para {destinatario}:\n{link}\n")
        return False

    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = "MenStyle - Recuperación de contraseña"
        msg["From"] = formataddr((SMTP_FROM_NAME, SMTP_USER))
        msg["To"] = destinatario

        html = _html_reset_password(nombre_usuario, token)
        msg.attach(MIMEText(html, "html", "utf-8"))

        with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=15) as server:
            server.starttls()
            server.login(SMTP_USER, SMTP_PASSWORD)
            server.sendmail(SMTP_USER, [destinatario], msg.as_string())

        logger.info("Email de reset enviado a %s", destinatario)
        return True

    except Exception as e:
        logger.error("Error enviando email a %s: %s", destinatario, e)
        return False