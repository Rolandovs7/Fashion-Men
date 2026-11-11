"""
Script de diagnóstico del flujo de pago.

Ejecuta un pago real contra la API (TestClient + PostgreSQL local) usando
las credenciales de Jimena (administradora de la empresa 1) y un pedido
temporal de otro usuario de la misma empresa. Al finalizar limpia todo.

Uso:
    cd backend
    ../.venv/bin/python test_pago.py

También admite una URL remota:
    MENSTYLE_BASE_URL=https://menstyle-api-n77g.onrender.com python test_pago.py
"""

import json
import os
import sys
import uuid

from fastapi.testclient import TestClient

from app.main import app
from app.core.database import SessionLocal
from app.models.notification import Notificacion
from app.models.order import Pedido
from app.models.payment import Pago
from app.models.user import Usuario

EMAIL_JIMENA = "jimenajahuira26@gmail.com"
PASSWORD_JIMENA = "Jimena2026@"
EMPRESA_ID = 1
SUCURSAL_ID = 4
MONTO = 100.00


def imprimir(titulo: str, status_code: int, payload) -> None:
    print(f"\n=== {titulo} ===")
    print(f"HTTP {status_code}")
    if isinstance(payload, str):
        print(payload)
    else:
        print(json.dumps(payload, ensure_ascii=False, indent=2, default=str))


def main() -> int:
    base_url = os.getenv("MENSTYLE_BASE_URL")
    cliente = TestClient(app, base_url=base_url) if base_url else TestClient(app)

    db = SessionLocal()
    pedido = None
    pedido_id = None
    dueno_id = None
    try:
        # Dueño distinto a Jimena pero de la misma empresa: ejercita el
        # bypass de administrador (permitir_ajeno).
        dueno = (
            db.query(Usuario)
            .filter(
                Usuario.empresa_id == EMPRESA_ID,
                Usuario.email != EMAIL_JIMENA,
                Usuario.activo.is_(True),
            )
            .first()
        )
        if dueno is None:
            print("ERROR: no hay otro usuario activo en la empresa 1.")
            return 1

        pedido = Pedido(
            usuario_id=dueno.id,
            sucursal_id=SUCURSAL_ID,
            empresa_id=EMPRESA_ID,
            estado="pendiente",
            total=MONTO,
            uuid_offline=f"test-pago-{uuid.uuid4().hex[:12]}",
        )
        db.add(pedido)
        db.commit()
        db.refresh(pedido)
        pedido_id = pedido.id
        dueno_id = dueno.id
        print(f"Pedido temporal creado: #{pedido_id} (dueño usuario {dueno_id}, total {MONTO})")

        # 1) Login de Jimena
        respuesta_login = cliente.post(
            "/api/auth/login",
            data={"username": EMAIL_JIMENA, "password": PASSWORD_JIMENA},
        )
        try:
            cuerpo_login = respuesta_login.json()
        except Exception:
            cuerpo_login = respuesta_login.text
        imprimir("LOGIN JIMENA", respuesta_login.status_code, cuerpo_login)
        if respuesta_login.status_code != 200:
            return 1

        token = cuerpo_login.get("access_token") if isinstance(cuerpo_login, dict) else None
        if not token:
            print("ERROR: la respuesta de login no trae access_token.")
            return 1

        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        }

        # 2) POST /api/pagos
        respuesta_pago = cliente.post(
            "/api/pagos",
            headers=headers,
            json={
                "pedido_id": pedido_id,
                "metodo": "tarjeta",
                "monto": MONTO,
                "referencia": "TEST-AUTOMATIZADO",
            },
        )
        try:
            cuerpo_pago = respuesta_pago.json()
        except Exception:
            cuerpo_pago = respuesta_pago.text
        imprimir("POST /api/pagos", respuesta_pago.status_code, cuerpo_pago)

        # 3) Consulta del pago registrado (para confirmar persistencia)
        respuesta_listado = cliente.get(
            f"/api/pagos/pedido/{pedido_id}",
            headers=headers,
        )
        try:
            cuerpo_listado = respuesta_listado.json()
        except Exception:
            cuerpo_listado = respuesta_listado.text
        imprimir(
            f"GET /api/pagos/pedido/{pedido_id}",
            respuesta_listado.status_code,
            cuerpo_listado,
        )

        return 0 if respuesta_pago.status_code == 201 else 2

    finally:
        # Limpieza: pagos, notificaciones del pago y pedido temporal.
        db.rollback()
        if pedido_id is not None:
            db.query(Pago).filter(Pago.pedido_id == pedido_id).delete(
                synchronize_session=False
            )
            db.query(Notificacion).filter(
                Notificacion.usuario_id == dueno_id,
                Notificacion.mensaje.like(f"%#{pedido_id}%"),
            ).delete(synchronize_session=False)
            db.query(Pedido).filter(Pedido.id == pedido_id).delete(
                synchronize_session=False
            )
            db.commit()
            print(f"\nCleanup: pedido #{pedido_id} y sus pagos/notificaciones eliminados.")
        db.close()


if __name__ == "__main__":
    sys.exit(main())
