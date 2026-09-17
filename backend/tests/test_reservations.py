from datetime import datetime, timedelta, timezone, timezone

def test_crear_reserva_exitosa(client, client_headers, seed_data):
    fecha_futura = (datetime.now(timezone.utc) + timedelta(days=2)).isoformat()
    payload = {
        "sucursal_id": seed_data["sucursal"].id,
        "fecha_reserva": fecha_futura,
        "observaciones": "Reserva de prueba",
        "detalles": [
            {
                "variante_id": seed_data["variante"].id,
                "cantidad": 2
            }
        ]
    }
    response = client.post("/reservas", json=payload, headers=client_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["sucursal_id"] == seed_data["sucursal"].id
    assert data["estado"] == "pendiente"
    assert len(data["detalles"]) == 1


def test_crear_reserva_supera_stock(client, client_headers, seed_data):
    fecha_futura = (datetime.now(timezone.utc) + timedelta(days=2)).isoformat()
    payload = {
        "sucursal_id": seed_data["sucursal"].id,
        "fecha_reserva": fecha_futura,
        "detalles": [
            {
                "variante_id": seed_data["variante"].id,
                "cantidad": 9999
            }
        ]
    }
    response = client.post("/reservas", json=payload, headers=client_headers)
    assert response.status_code == 400
    assert "Stock insuficiente" in response.json()["detail"]


def test_listar_mis_reservas(client, client_headers, seed_data):
    response = client.get("/reservas", headers=client_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)


def test_cancelar_reserva_cliente(client, client_headers, seed_data):
    fecha_futura = (datetime.now(timezone.utc) + timedelta(days=2)).isoformat()
    payload = {
        "sucursal_id": seed_data["sucursal"].id,
        "fecha_reserva": fecha_futura,
        "detalles": [{"variante_id": seed_data["variante"].id, "cantidad": 1}]
    }
    res_crear = client.post("/reservas", json=payload, headers=client_headers).json()
    reserva_id = res_crear["id"]

    # Cancelar reserva
    response = client.put(f"/reservas/{reserva_id}/cancelar", headers=client_headers)
    assert response.status_code == 200
    assert response.json()["estado"] == "cancelada"


def test_cancelar_reserva_ya_cancelada(client, client_headers, seed_data):
    fecha_futura = (datetime.now(timezone.utc) + timedelta(days=2)).isoformat()
    payload = {
        "sucursal_id": seed_data["sucursal"].id,
        "fecha_reserva": fecha_futura,
        "detalles": [{"variante_id": seed_data["variante"].id, "cantidad": 1}]
    }
    res_crear = client.post("/reservas", json=payload, headers=client_headers).json()
    reserva_id = res_crear["id"]

    # Primera cancelación
    client.put(f"/reservas/{reserva_id}/cancelar", headers=client_headers)

    # Segunda cancelación debe retornar 400
    response = client.put(f"/reservas/{reserva_id}/cancelar", headers=client_headers)
    assert response.status_code == 400
    assert "ya se encuentra" in response.json()["detail"] or "cancelada" in response.json()["detail"]


def test_cambiar_estado_reserva_admin(client, admin_headers, client_headers, seed_data):
    fecha_futura = (datetime.now(timezone.utc) + timedelta(days=2)).isoformat()
    payload = {
        "sucursal_id": seed_data["sucursal"].id,
        "fecha_reserva": fecha_futura,
        "detalles": [{"variante_id": seed_data["variante"].id, "cantidad": 1}]
    }
    res_crear = client.post("/reservas", json=payload, headers=client_headers).json()
    reserva_id = res_crear["id"]

    payload_estado = {"nuevo_estado": "confirmada"}
    response = client.put(f"/reservas/{reserva_id}/estado", json=payload_estado, headers=admin_headers)
    assert response.status_code == 200
    assert response.json()["estado"] == "confirmada"
