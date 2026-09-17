def test_crear_pedido_carrito_vacio(client, client_headers, seed_data):
    # Asegurar que el carrito esté vacío
    client.delete("/carrito", headers=client_headers)
    
    payload = {"sucursal_id": seed_data["sucursal"].id}
    response = client.post("/pedidos", json=payload, headers=client_headers)
    assert response.status_code == 400
    assert "carrito de compras está vacío" in response.json()["detail"]


def test_crear_pedido_exitoso(client, client_headers, seed_data):
    # 1. Vaciar carrito e insertar producto
    client.delete("/carrito", headers=client_headers)
    client.post("/carrito/items", json={"variante_id": seed_data["variante"].id, "cantidad": 2}, headers=client_headers)

    # 2. Crear pedido
    payload = {"sucursal_id": seed_data["sucursal"].id}
    response = client.post("/pedidos", json=payload, headers=client_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["estado"] == "pendiente"
    assert len(data["detalles"]) == 1
    assert data["detalles"][0]["cantidad"] == 2
    assert data["total"] > 0

    # 3. El carrito debe haber quedado vacío
    carrito = client.get("/carrito", headers=client_headers).json()
    assert len(carrito["detalles"]) == 0


def test_listar_mis_pedidos(client, client_headers):
    response = client.get("/pedidos", headers=client_headers)
    assert response.status_code == 200
    assert isinstance(response.json(), list)


def test_cancelar_pedido_cliente_exitoso(client, client_headers, seed_data):
    # Preparar pedido
    client.delete("/carrito", headers=client_headers)
    client.post("/carrito/items", json={"variante_id": seed_data["variante"].id, "cantidad": 1}, headers=client_headers)
    pedido = client.post("/pedidos", json={"sucursal_id": seed_data["sucursal"].id}, headers=client_headers).json()

    # Cancelar pedido
    response = client.put(f"/pedidos/{pedido['id']}/cancelar", headers=client_headers)
    assert response.status_code == 200
    assert response.json()["estado"] == "cancelado"


def test_cancelar_pedido_ya_cancelado(client, client_headers, seed_data):
    # Preparar pedido
    client.delete("/carrito", headers=client_headers)
    client.post("/carrito/items", json={"variante_id": seed_data["variante"].id, "cantidad": 1}, headers=client_headers)
    pedido = client.post("/pedidos", json={"sucursal_id": seed_data["sucursal"].id}, headers=client_headers).json()

    # Primera cancelación
    client.put(f"/pedidos/{pedido['id']}/cancelar", headers=client_headers)

    # Segunda cancelación
    response = client.put(f"/pedidos/{pedido['id']}/cancelar", headers=client_headers)
    assert response.status_code == 400
    assert "No se puede cancelar" in response.json()["detail"]


def test_cambiar_estado_pedido_admin(client, admin_headers, client_headers, seed_data):
    # Preparar pedido
    client.delete("/carrito", headers=client_headers)
    client.post("/carrito/items", json={"variante_id": seed_data["variante"].id, "cantidad": 1}, headers=client_headers)
    pedido = client.post("/pedidos", json={"sucursal_id": seed_data["sucursal"].id}, headers=client_headers).json()

    payload_estado = {
        "nuevo_estado": "procesando"
    }
    response = client.put(f"/pedidos/{pedido['id']}/estado", json=payload_estado, headers=admin_headers)
    assert response.status_code == 200
    assert response.json()["estado"] == "procesando"
