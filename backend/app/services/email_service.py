"""
Servicio de envío de emails vía Brevo API HTTP (puerto 443).

- Recuperación de contraseña: usa Brevo API (requests) - existente.
- Correos SaaS (bienvenida/pago): usa SDK brevo-python (API transaccional).
  Render Free bloquea SMTP; Brevo HTTP funciona correctamente.

Variables de entorno:
  BREVO_API_KEY        (obligatoria para envío real)
  BREVO_SENDER_EMAIL   (opcional, remitente verificado en Brevo)
  BREVO_SENDER_NAME    (opcional, default: MenStyle SaaS)
"""

import os
import logging
from typing import Any

import requests

logger = logging.getLogger(__name__)

# --- Configuración Brevo ---
BREVO_API_KEY = os.getenv("BREVO_API_KEY", "")
SMTP_FROM_NAME = os.getenv("SMTP_FROM_NAME", "MenStyle")
SMTP_USER = os.getenv("SMTP_USER", "")
FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:4200").rstrip("/")
BREVO_API_URL = "https://api.brevo.com/v3/smtp/email"

# Remitente para correos transaccionales (debe estar verificado en Brevo)
BREVO_SENDER_EMAIL = (
    os.getenv("BREVO_SENDER_EMAIL")
    or os.getenv("MAIL_FROM")
    or "rolandosoliz19@gmail.com"
)
BREVO_SENDER_NAME = os.getenv("BREVO_SENDER_NAME", "MenStyle SaaS")


def _brevo_configurado() -> bool:
    return bool(BREVO_API_KEY)


def _html_reset_password(nombre: str, token: str) -> str:
    link = f"{FRONTEND_URL}/reset-password?token={token}"
    return f"""<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"></head>
<body style="font-family:Arial,Helvetica,sans-serif;background:#f5f5f5;margin:0;padding:20px;">
  <div style="max-width:600px;margin:0 auto;background:#fff;border-radius:16px;padding:32px 24px;">
    <div style="font-size:28px;font-weight:900;letter-spacing:3px;color:#000;text-align:center;">MENSTYLE</div>
    <div style="text-align:center;color:#888;font-size:13px;margin:6px 0 24px 0;">Plataforma E-Commerce</div>
    <h2 style="color:#111;margin:0 0 12px 0;">Hola {nombre},</h2>
    <p style="color:#444;line-height:1.6;">Recibimos una solicitud para restablecer tu contraseña.</p>
    <p style="text-align:center;margin:24px 0;">
      <a href="{link}" style="display:inline-block;background:#000;color:#fff;padding:14px 28px;border-radius:12px;text-decoration:none;font-weight:bold;">Restablecer contraseña</a>
    </p>
    <p style="color:#666;font-size:12px;word-break:break-all;background:#f5f5f5;padding:10px;border-radius:8px;">{link}</p>
    <p style="color:#444;"><strong>Este enlace expira en 30 minutos.</strong></p>
    <p style="color:#999;font-size:12px;text-align:center;margin-top:24px;">MenStyle · No respondas a este correo.</p>
  </div>
</body></html>"""


def enviar_email_reset_password(destinatario: str, nombre_usuario: str, token: str) -> bool:
    """Envía el email de recuperación de contraseña vía Brevo API HTTP (requests)."""
    if not _brevo_configurado():
        logger.warning("Brevo no configurado (BREVO_API_KEY). No se envió a %s.", destinatario)
        link = f"{FRONTEND_URL}/reset-password?token={token}"
        print(f"\n📧 [MODO DEV] Link de reset para {destinatario}:\n{link}\n")
        return False
    try:
        headers = {
            "accept": "application/json",
            "api-key": BREVO_API_KEY,
            "content-type": "application/json",
        }
        sender_email = SMTP_USER or BREVO_SENDER_EMAIL
        payload = {
            "sender": {"name": SMTP_FROM_NAME, "email": sender_email},
            "to": [{"email": destinatario, "name": nombre_usuario}],
            "subject": "MenStyle - Recuperación de contraseña",
            "htmlContent": _html_reset_password(nombre_usuario, token),
        }
        response = requests.post(BREVO_API_URL, headers=headers, json=payload, timeout=15)
        if response.status_code in (200, 201, 202):
            logger.info("Email de reset enviado a %s vía Brevo", destinatario)
            print(f"✅ Email enviado a {destinatario}")
            return True
        logger.error("Error Brevo a %s: status=%s body=%s", destinatario, response.status_code, response.text)
        print(f"❌ Error Brevo: {response.status_code} - {response.text}")
        return False
    except Exception as e:
        logger.error("Error enviando reset a %s: %s", destinatario, e)
        print(f"❌ Excepción: {e}")
        return False


# --- Correos SaaS vía brevo-python (API HTTP transaccional) ---

def _obtener_cliente_brevo() -> Any:
    if not BREVO_API_KEY:
        return None
    try:
        from brevo import Brevo
        return Brevo(api_key=BREVO_API_KEY)
    except Exception as e:
        logger.error("No se pudo inicializar cliente Brevo: %s", e)
        return None


def _enviar_transaccional(asunto: str, destinatario: str, html: str) -> bool:
    """Envía un correo transaccional vía Brevo. Nunca lanza: retorna False si falla."""
    if not destinatario:
        logger.warning("Email transaccional omitido: destinatario vacío (%s)", asunto)
        return False
    if not _brevo_configurado():
        logger.warning("BREVO_API_KEY no configurada. No se envió: %s a %s", asunto, destinatario)
        print(f"⚠️ [EMAIL NO ENVIADO - BREVO_API_KEY no configurada] to={destinatario} subject={asunto}")
        return False
    try:
        client = _obtener_cliente_brevo()
        if client is None:
            print(f"⚠️ [EMAIL NO ENVIADO - cliente Brevo no disponible] to={destinatario} subject={asunto}")
            return False

        from brevo.transactional_emails.types.send_transac_email_request_sender import (
            SendTransacEmailRequestSender,
        )
        from brevo.transactional_emails.types.send_transac_email_request_to_item import (
            SendTransacEmailRequestToItem,
        )

        # Remitente verificado en Brevo (preferir rolandosoliz19@gmail.com; fallback configurable)
        sender_email = BREVO_SENDER_EMAIL or "rolando.vsoliz@gmail.com"
        sender = SendTransacEmailRequestSender(email=sender_email, name=BREVO_SENDER_NAME)
        to = [SendTransacEmailRequestToItem(email=destinatario)]

        resp = client.transactional_emails.send_transac_email(
            subject=asunto,
            sender=sender,
            to=to,
            html_content=html,
        )
        logger.info("Email transaccional enviado a %s: %s (resp=%s)", destinatario, asunto, resp)
        print(f"✅ Email enviado a {destinatario}: {asunto}")
        return True
    except Exception as e:
        # Importante: no romper el flujo (pago/creación de empresa) si falla el correo
        logger.error("Error enviando email transaccional a %s (%s): %s", destinatario, asunto, e)
        print(f"❌ Error enviando email a {destinatario} ({asunto}): {e}")
        # Intento de fallback con remitente alternativo si el principal falla por verificación
        try:
            if BREVO_SENDER_EMAIL != "rolando.vsoliz@gmail.com":
                client = _obtener_cliente_brevo()
                if client is None:
                    return False
                from brevo.transactional_emails.types.send_transac_email_request_sender import (
                    SendTransacEmailRequestSender,
                )
                from brevo.transactional_emails.types.send_transac_email_request_to_item import (
                    SendTransacEmailRequestToItem,
                )
                sender = SendTransacEmailRequestSender(email="rolando.vsoliz@gmail.com", name=BREVO_SENDER_NAME)
                to = [SendTransacEmailRequestToItem(email=destinatario)]
                client.transactional_emails.send_transac_email(
                    subject=asunto, sender=sender, to=to, html_content=html,
                )
                print(f"✅ Email enviado (fallback sender rolando.vsoliz@gmail.com) a {destinatario}: {asunto}")
                return True
        except Exception as e2:
            logger.error("Fallback sender también falló a %s: %s", destinatario, e2)
            print(f"❌ Fallback sender también falló a {destinatario}: {e2}")
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
    """[SaaS] Envía correo de bienvenida al registrar una empresa (Brevo API)."""
    try:
        if not email:
            logger.warning("enviar_correo_bienvenida: email vacío, se omite.")
            return False
        asunto = "Bienvenido a MenStyle SaaS"
        html = _plantilla_html(
            "¡Bienvenido a MenStyle!",
            f"<p>Tu empresa <strong>{nombre_empresa}</strong> fue registrada correctamente.</p>"
            f"<p>Plan inicial asignado: <strong>{plan}</strong>.</p>"
            f"<p>Ya podés empezar a gestionar tu catálogo, ventas e inventario.</p>",
        )
        return _enviar_transaccional(asunto, email, html)
    except Exception as e:
        logger.error("Fallo enviar_correo_bienvenida a %s: %s", email, e)
        print(f"❌ Fallo enviar_correo_bienvenida a {email}: {e}")
        return False


def enviar_correo_pago(email: str, nombre_empresa: str, plan: str, monto) -> bool:
    """[SaaS/CU02] Envía confirmación de pago/cambio de plan (Brevo API)."""
    try:
        if not email:
            logger.warning("enviar_correo_pago: email vacío, se omite.")
            return False
        try:
            monto_fmt = f"{float(monto):.2f}"
        except Exception:
            monto_fmt = str(monto)
        asunto = "Confirmación de pago - MenStyle SaaS"
        html = _plantilla_html(
            "Confirmación de pago",
            f"<p>Recibimos la confirmación de tu pago.</p>"
            f"<ul><li><strong>Empresa:</strong> {nombre_empresa}</li>"
            f"<li><strong>Plan:</strong> {plan}</li>"
            f"<li><strong>Monto:</strong> Bs. {monto_fmt}</li></ul>"
            f"<p>Tu suscripción fue actualizada correctamente.</p>",
        )
        return _enviar_transaccional(asunto, email, html)
    except Exception as e:
        logger.error("Fallo enviar_correo_pago a %s: %s", email, e)
        print(f"❌ Fallo enviar_correo_pago a {email}: {e}")
        return False
