def test_registrar_pago_exitoso(client, client_headers, seed_data):
    # Crear pedido
    client.delete("/carrito", headers=client_headers)
    client.post("/carrito/items", json={"variante_id": seed_data["variante"].id, "cantidad": 2}, headers=client_headers)
    pedido = client.post("/pedidos", json={"sucursal_id": seed_data["sucursal"].id}, headers=client_headers).json()

    payload_pago = {
        "pedido_id": pedido["id"],
        "metodo": "tarjeta",
        "monto": pedido["total"],
        "referencia": "REF123456"
    }

    response = client.post("/pagos", json=payload_pago, headers=client_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["pedido_id"] == pedido["id"]
    assert data["estado"] == "aprobado"
    assert data["monto"] == pedido["total"]

    # Verificar que el estado del pedido haya cambiado a 'pagado'
    pedido_actualizado = client.get(f"/pedidos/{pedido['id']}", headers=client_headers).json()
    assert pedido_actualizado["estado"] == "pagado"


def test_pagar_pedido_inexistente(client, client_headers):
    payload_pago = {
        "pedido_id": 99999,
        "metodo": "tarjeta",
        "monto": 100.0,
        "referencia": "REF999"
    }
    response = client.post("/pagos", json=payload_pago, headers=client_headers)
    assert response.status_code == 404


def test_pago_duplicado(client, client_headers, seed_data):
    # Crear y pagar pedido
    client.delete("/carrito", headers=client_headers)
    client.post("/carrito/items", json={"variante_id": seed_data["variante"].id, "cantidad": 1}, headers=client_headers)
    pedido = client.post("/pedidos", json={"sucursal_id": seed_data["sucursal"].id}, headers=client_headers).json()

    payload_pago = {
        "pedido_id": pedido["id"],
        "metodo": "efectivo",
        "monto": pedido["total"]
    }
    client.post("/pagos", json=payload_pago, headers=client_headers)

    # Segundo intento de pago debe fallar con 400
    response = client.post("/pagos", json=payload_pago, headers=client_headers)
    assert response.status_code == 400
    assert "No se pueden registrar pagos" in response.json()["detail"] or "Ya existe un pago" in response.json()["detail"]


def test_pago_monto_incorrecto(client, client_headers, seed_data):
    client.delete("/carrito", headers=client_headers)
    client.post("/carrito/items", json={"variante_id": seed_data["variante"].id, "cantidad": 1}, headers=client_headers)
    pedido = client.post("/pedidos", json={"sucursal_id": seed_data["sucursal"].id}, headers=client_headers).json()

    payload_pago = {
        "pedido_id": pedido["id"],
        "metodo": "qr",
        "monto": pedido["total"] + 10.0
    }
    response = client.post("/pagos", json=payload_pago, headers=client_headers)
    assert response.status_code == 400
    assert "monto del pago" in response.json()["detail"]


def test_listar_pagos_pedido(client, client_headers, seed_data):
    client.delete("/carrito", headers=client_headers)
    client.post("/carrito/items", json={"variante_id": seed_data["variante"].id, "cantidad": 1}, headers=client_headers)
    pedido = client.post("/pedidos", json={"sucursal_id": seed_data["sucursal"].id}, headers=client_headers).json()

    payload_pago = {
        "pedido_id": pedido["id"],
        "metodo": "tarjeta",
        "monto": pedido["total"]
    }
    client.post("/pagos", json=payload_pago, headers=client_headers)

    response = client.get(f"/pagos/pedido/{pedido['id']}", headers=client_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) == 1
