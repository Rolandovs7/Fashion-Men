"""
Servicio de envío de emails vía Brevo API HTTP.

Uso:
    from app.services.email_service import enviar_email_reset_password

    exito = enviar_email_reset_password(
        destinatario="usuario@gmail.com",
        nombre_usuario="Juan",
        token="abc-123-xyz"
    )

Configuración (.env o variables de entorno):
    BREVO_API_KEY      xkeysib-...  (obligatoria)
    SMTP_FROM_NAME     MenStyle
    SMTP_USER          tu-email-verificado-en-brevo@ejemplo.com
    FRONTEND_URL       https://menstyle-web-0de9.onrender.com

NOTA: Usamos la API HTTP de Brevo en lugar de SMTP porque Render
(free tier) bloquea los puertos SMTP salientes (587, 465, 25).
"""
import os
import logging
import requests

logger = logging.getLogger(__name__)

# Configuración
BREVO_API_KEY = os.getenv("BREVO_API_KEY", "")
SMTP_FROM_NAME = os.getenv("SMTP_FROM_NAME", "MenStyle")
SMTP_USER = os.getenv("SMTP_USER", "")
FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:4200").rstrip("/")

# Endpoint de Brevo
BREVO_API_URL = "https://api.brevo.com/v3/smtp/email"


def _brevo_configurado() -> bool:
    """Verifica si la API key de Brevo está configurada."""
    return bool(BREVO_API_KEY and SMTP_USER)


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
    Envía el email con el link de recuperación de contraseña vía Brevo API.
    """
    if not _brevo_configurado():
        logger.warning(
            "Brevo no configurado (falta BREVO_API_KEY o SMTP_USER). "
            "No se envió email a %s.",
            destinatario
        )
        link = f"{FRONTEND_URL}/reset-password?token={token}"
        print(f"\n📧 [MODO DEV] Link de reset para {destinatario}:\n{link}\n")
        return False

    try:
        headers = {
            "accept": "application/json",
            "api-key": BREVO_API_KEY,
            "content-type": "application/json",
        }

        payload = {
            "sender": {
                "name": SMTP_FROM_NAME,
                "email": SMTP_USER,
            },
            "to": [
                {
                    "email": destinatario,
                    "name": nombre_usuario,
                }
            ],
            "subject": "MenStyle - Recuperación de contraseña",
            "htmlContent": _html_reset_password(nombre_usuario, token),
        }

        response = requests.post(
            BREVO_API_URL,
            headers=headers,
            json=payload,
            timeout=15,
        )

        if response.status_code in (200, 201, 202):
            logger.info("Email de reset enviado a %s vía Brevo", destinatario)
            print(f"✅ Email enviado a {destinatario}")
            return True
        else:
            logger.error(
                "Error de Brevo al enviar a %s: status=%s, body=%s",
                destinatario, response.status_code, response.text
            )
            print(f"❌ Error Brevo: {response.status_code} - {response.text}")
            return False

    except Exception as e:
        logger.error("Error enviando email a %s: %s", destinatario, e)
        print(f"❌ Excepción: {e}")
        return False