"""
Servicio de envío de emails.

- Recuperación de contraseña: mantiene integración Brevo (o fallback dev) para no
  romper auth existente.
- Correos SaaS (bienvenida/pago): envío real vía SMTP (Gmail) usando fastapi-mail.
  Las credenciales se leen de variables de entorno (NO commitear contraseñas).
"""

import os
import logging
import asyncio
from typing import Optional

import requests
from fastapi_mail import ConnectionConfig, FastMail, MessageSchema, MessageType

logger = logging.getLogger(__name__)

# --- Configuración Brevo (reset password, existente) ---
BREVO_API_KEY = os.getenv("BREVO_API_KEY", "")
SMTP_FROM_NAME = os.getenv("SMTP_FROM_NAME", "MenStyle")
SMTP_USER = os.getenv("SMTP_USER", "")
FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:4200").rstrip("/")
BREVO_API_URL = "https://api.brevo.com/v3/smtp/email"

# --- Configuración SMTP (fastapi-mail, correos SaaS) ---
MAIL_USERNAME = os.getenv("MAIL_USERNAME", "")
MAIL_PASSWORD = os.getenv("MAIL_PASSWORD", "")
MAIL_FROM = os.getenv("MAIL_FROM", "") or MAIL_USERNAME
MAIL_SERVER = os.getenv("MAIL_SERVER", "smtp.gmail.com")
MAIL_PORT = int(os.getenv("MAIL_PORT", "587"))


def _brevo_configurado() -> bool:
    return bool(BREVO_API_KEY and SMTP_USER)


def _html_reset_password(nombre: str, token: str) -> str:
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


def enviar_email_reset_password(destinatario: str, nombre_usuario: str, token: str) -> bool:
    """Envía el email de recuperación de contraseña vía Brevo API (existente)."""
    if not _brevo_configurado():
        logger.warning("Brevo no configurado. No se envió email a %s.", destinatario)
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
            "sender": {"name": SMTP_FROM_NAME, "email": SMTP_USER},
            "to": [{"email": destinatario, "name": nombre_usuario}],
            "subject": "MenStyle - Recuperación de contraseña",
            "htmlContent": _html_reset_password(nombre_usuario, token),
        }
        response = requests.post(BREVO_API_URL, headers=headers, json=payload, timeout=15)
        if getattr(response, "status_code", 0) in (200, 201, 202):
            logger.info("Email de reset enviado a %s vía Brevo", destinatario)
            print(f"✅ Email enviado a {destinatario}")
            return True
        logger.error("Error Brevo a %s: status=%s body=%s", destinatario, response.status_code, response.text)
        print(f"❌ Error Brevo: {response.status_code} - {response.text}")
        return False
    except Exception as e:
        logger.error("Error enviando email a %s: %s", destinatario, e)
        print(f"❌ Excepción: {e}")
        return False


# --- Correos SaaS reales vía SMTP (fastapi-mail) ---

def _smtp_configurado() -> bool:
    return bool(MAIL_USERNAME and MAIL_PASSWORD and MAIL_FROM)


def _obtener_fastmail() -> Optional[FastMail]:
    if not _smtp_configurado():
        return None
    conf = ConnectionConfig(
        MAIL_USERNAME=MAIL_USERNAME,
        MAIL_PASSWORD=MAIL_PASSWORD,
        MAIL_FROM=MAIL_FROM,
        MAIL_PORT=MAIL_PORT,
        MAIL_SERVER=MAIL_SERVER,
        MAIL_STARTTLS=True,
        MAIL_SSL_TLS=False,
        USE_CREDENTIALS=True,
        VALIDATE_CERTS=True,
    )
    return FastMail(conf)


async def _enviar_async(asunto: str, destinatarios: list[str], cuerpo_texto: str, cuerpo_html: str) -> bool:
    fm = _obtener_fastmail()
    if fm is None:
        logger.warning("SMTP no configurado (MAIL_USERNAME/MAIL_PASSWORD/MAIL_FROM). No se envió: %s", asunto)
        print(f"⚠️ [EMAIL NO ENVIADO - SMTP no configurado] to={destinatarios} subject={asunto}")
        return False
    message = MessageSchema(
        subject=asunto,
        recipients=destinatarios,
        body=cuerpo_html,
        subtype=MessageType.html,
    )
    await fm.send_message(message)
    logger.info("Email enviado a %s: %s", destinatarios, asunto)
    print(f"✅ Email enviado a {destinatarios}: {asunto}")
    return True


def _enviar_sync(asunto: str, destinatarios: list[str], cuerpo_texto: str, cuerpo_html: str) -> bool:
    try:
        return asyncio.run(_enviar_async(asunto, destinatarios, cuerpo_texto, cuerpo_html))
    except RuntimeError:
        # Si ya hay un event loop en este hilo, ejecutar en un loop nuevo aislado
        try:
            loop = asyncio.new_event_loop()
            try:
                return loop.run_until_complete(_enviar_async(asunto, destinatarios, cuerpo_texto, cuerpo_html))
            finally:
                loop.close()
        except Exception as e:
            logger.error("Error enviando email (loop) a %s: %s", destinatarios, e)
            print(f"❌ Error enviando email a {destinatarios}: {e}")
            return False
    except Exception as e:
        logger.error("Error enviando email a %s: %s", destinatarios, e)
        print(f"❌ Error enviando email a {destinatarios}: {e}")
        return False


def _plantilla_html(titulo: str, contenido_html: str) -> str:
    return f"""<!DOCTYPE html>
<html lang="es"><head><meta charset="UTF-8"></head>
<body style="font-family:Arial,Helvetica,sans-serif;background:#f5f5f5;margin:0;padding:20px;">
  <div style="max-width:600px;margin:0 auto;background:#fff;border-radius:12px;padding:28px 24px;">
    <div style="font-size:24px;font-weight:900;letter-spacing:2px;color:#000;text-align:center;">MENSTYLE</div>
    <h2 style="color:#111;margin:20px 0 12px 0;">{titulo}</h2>
    <div style="color:#333;line-height:1.6;font-size:15px;">{contenido_html}</div>
    <hr style="border:none;border-top:1px solid #eee;margin:24px 0;" />
    <div style="color:#888;font-size:12px;text-align:center;">MenStyle SaaS · No respondas a este correo.</div>
  </div>
</body></html>"""


def enviar_correo_bienvenida(email: str, nombre_empresa: str, plan: str) -> bool:
    """[SaaS] Envía correo real de bienvenida al registrar una empresa (SMTP)."""
    if not email:
        logger.warning("enviar_correo_bienvenida: email vacío, se omite.")
        return False
    try:
        asunto = "Bienvenido a MenStyle SaaS"
        cuerpo = (
            f"Hola,\n\n¡Bienvenidos a MenStyle!\n\n"
            f"Tu empresa \"{nombre_empresa}\" fue registrada correctamente.\n"
            f"Plan inicial asignado: {plan}.\n\nEquipo MenStyle"
        )
        html = _plantilla_html(
            "¡Bienvenido a MenStyle!",
            f"<p>Tu empresa <strong>{nombre_empresa}</strong> fue registrada correctamente.</p>"
            f"<p>Plan inicial asignado: <strong>{plan}</strong>.</p>"
            f"<p>Ya podés empezar a gestionar tu catálogo, ventas e inventario.</p>",
        )
        return _enviar_sync(asunto, [email], cuerpo, html)
    except Exception as e:
        # No romper el flujo de la app si falla el correo
        logger.error("Fallo enviar_correo_bienvenida a %s: %s", email, e)
        print(f"❌ Fallo enviar_correo_bienvenida a {email}: {e}")
        return False


def enviar_correo_pago(email: str, nombre_empresa: str, plan: str, monto) -> bool:
    """[SaaS/CU02] Envía correo real de confirmación de pago/cambio de plan (SMTP)."""
    if not email:
        logger.warning("enviar_correo_pago: email vacío, se omite.")
        return False
    try:
        try:
            monto_fmt = f"{float(monto):.2f}"
        except Exception:
            monto_fmt = str(monto)
        asunto = "Confirmación de pago - MenStyle SaaS"
        cuerpo = (
            f"Hola,\n\nRecibimos la confirmación de tu pago.\n\n"
            f"Empresa: {nombre_empresa}\nPlan: {plan}\nMonto: Bs. {monto_fmt}\n\nEquipo MenStyle"
        )
        html = _plantilla_html(
            "Confirmación de pago",
            f"<p>Recibimos la confirmación de tu pago.</p>"
            f"<ul><li><strong>Empresa:</strong> {nombre_empresa}</li>"
            f"<li><strong>Plan:</strong> {plan}</li>"
            f"<li><strong>Monto:</strong> Bs. {monto_fmt}</li></ul>"
            f"<p>Tu suscripción fue actualizada correctamente.</p>",
        )
        return _enviar_sync(asunto, [email], cuerpo, html)
    except Exception as e:
        # No romper el flujo de la app si falla el correo
        logger.error("Fallo enviar_correo_pago a %s: %s", email, e)
        print(f"❌ Fallo enviar_correo_pago a {email}: {e}")
        return False
