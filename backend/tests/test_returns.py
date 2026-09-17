def test_solicitar_devolucion_exitosa(client, client_headers, admin_headers, seed_data):
    # Crear pedido, pagar y cambiar estado a 'entregado'
    client.delete("/carrito", headers=client_headers)
    client.post("/carrito/items", json={"variante_id": seed_data["variante"].id, "cantidad": 3}, headers=client_headers)
    pedido = client.post("/pedidos", json={"sucursal_id": seed_data["sucursal"].id}, headers=client_headers).json()
    client.post("/pagos", json={"pedido_id": pedido["id"], "metodo": "tarjeta", "monto": pedido["total"]}, headers=client_headers)
    client.put(f"/pedidos/{pedido['id']}/estado", json={"nuevo_estado": "entregado"}, headers=admin_headers)

    payload_dev = {
        "pedido_id": pedido["id"],
        "variante_id": seed_data["variante"].id,
        "cantidad": 1,
        "motivo": "Talla incorrecta"
    }

    response = client.post("/devoluciones", json=payload_dev, headers=client_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["pedido_id"] == pedido["id"]
    assert data["estado"] == "solicitada"
    assert data["cantidad"] == 1


def test_devolucion_pedido_no_entregado_o_invalido(client, client_headers, seed_data):
    # Crear pedido en estado 'pendiente' (sin pagar)
    client.delete("/carrito", headers=client_headers)
    client.post("/carrito/items", json={"variante_id": seed_data["variante"].id, "cantidad": 2}, headers=client_headers)
    pedido = client.post("/pedidos", json={"sucursal_id": seed_data["sucursal"].id}, headers=client_headers).json()

    payload_dev = {
        "pedido_id": pedido["id"],
        "variante_id": seed_data["variante"].id,
        "cantidad": 1,
        "motivo": "Defecto de fábrica"
    }

    response = client.post("/devoluciones", json=payload_dev, headers=client_headers)
    assert response.status_code == 400
    assert "No se pueden solicitar devoluciones" in response.json()["detail"]


def test_devolucion_cantidad_superior_a_comprada(client, client_headers, seed_data):
    client.delete("/carrito", headers=client_headers)
    client.post("/carrito/items", json={"variante_id": seed_data["variante"].id, "cantidad": 2}, headers=client_headers)
    pedido = client.post("/pedidos", json={"sucursal_id": seed_data["sucursal"].id}, headers=client_headers).json()
    client.post("/pagos", json={"pedido_id": pedido["id"], "metodo": "tarjeta", "monto": pedido["total"]}, headers=client_headers)

    payload_dev = {
        "pedido_id": pedido["id"],
        "variante_id": seed_data["variante"].id,
        "cantidad": 5, # Compró solo 2
        "motivo": "Intento de devolver más"
    }

    response = client.post("/devoluciones", json=payload_dev, headers=client_headers)
    assert response.status_code == 400
    assert "supera el máximo disponible" in response.json()["detail"]


def test_completar_devolucion_admin_y_restaurar_stock(client, client_headers, admin_headers, seed_data):
    client.delete("/carrito", headers=client_headers)
    client.post("/carrito/items", json={"variante_id": seed_data["variante"].id, "cantidad": 2}, headers=client_headers)
    pedido = client.post("/pedidos", json={"sucursal_id": seed_data["sucursal"].id}, headers=client_headers).json()
    client.post("/pagos", json={"pedido_id": pedido["id"], "metodo": "tarjeta", "monto": pedido["total"]}, headers=client_headers)

    dev = client.post("/devoluciones", json={
        "pedido_id": pedido["id"],
        "variante_id": seed_data["variante"].id,
        "cantidad": 1,
        "motivo": "Cambio por otra prenda"
    }, headers=client_headers).json()

    # Admin completa la devolución indicando la sucursal
    payload_admin = {
        "nuevo_estado": "completada",
        "sucursal_id": seed_data["sucursal"].id
    }
    response = client.put(f"/devoluciones/{dev['id']}/estado", json=payload_admin, headers=admin_headers)
    assert response.status_code == 200
    assert response.json()["estado"] == "completada"

    # Intentar modificar el estado de una devolución completada debe dar 400 Bad Request
    response_repetido = client.put(f"/devoluciones/{dev['id']}/estado", json=payload_admin, headers=admin_headers)
    assert response_repetido.status_code == 400
    assert "estado final" in response_repetido.json()["detail"]


def test_listar_mis_devoluciones(client, client_headers):
    response = client.get("/devoluciones", headers=client_headers)
    assert response.status_code == 200
    assert isinstance(response.json(), list)
