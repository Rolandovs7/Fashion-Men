def test_obtener_carrito_vacio(client, client_headers):
    response = client.get("/carrito", headers=client_headers)
    assert response.status_code == 200
    data = response.json()
    assert "detalles" in data
    assert len(data["detalles"]) == 0


def test_agregar_item_al_carrito(client, client_headers, seed_data):
    payload = {
        "variante_id": seed_data["variante"].id,
        "cantidad": 2
    }
    response = client.post("/carrito/items", json=payload, headers=client_headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data["detalles"]) == 1
    assert data["detalles"][0]["variante_id"] == seed_data["variante"].id
    assert data["detalles"][0]["cantidad"] == 2


def test_actualizar_item_carrito(client, client_headers, seed_data):
    # Asegurar que hay un item
    payload_agregar = {
        "variante_id": seed_data["variante"].id,
        "cantidad": 1
    }
    client.post("/carrito/items", json=payload_agregar, headers=client_headers)
    
    # Obtener el detalle_id
    carrito_res = client.get("/carrito", headers=client_headers).json()
    detalle_id = carrito_res["detalles"][0]["id"]

    # Actualizar la cantidad a 5
    payload_actualizar = {"cantidad": 5}
    response = client.put(f"/carrito/items/{detalle_id}", json=payload_actualizar, headers=client_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["detalles"][0]["cantidad"] == 5


def test_eliminar_item_carrito(client, client_headers, seed_data):
    # Agregar item
    payload_agregar = {
        "variante_id": seed_data["variante"].id,
        "cantidad": 3
    }
    client.post("/carrito/items", json=payload_agregar, headers=client_headers)
    
    carrito_res = client.get("/carrito", headers=client_headers).json()
    detalle_id = carrito_res["detalles"][0]["id"]

    # Eliminar
    response = client.delete(f"/carrito/items/{detalle_id}", headers=client_headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data["detalles"]) == 0


def test_vaciar_carrito(client, client_headers, seed_data):
    # Agregar item
    client.post("/carrito/items", json={"variante_id": seed_data["variante"].id, "cantidad": 2}, headers=client_headers)
    
    # Vaciar
    response = client.delete("/carrito", headers=client_headers)
    assert response.status_code == 200
    assert len(response.json()["detalles"]) == 0


def test_agregar_item_cantidad_invalida(client, client_headers, seed_data):
    payload = {
        "variante_id": seed_data["variante"].id,
        "cantidad": 0
    }
    response = client.post("/carrito/items", json=payload, headers=client_headers)
    assert response.status_code in [400, 422]


def test_carrito_sin_autenticacion(client):
    response = client.get("/carrito")
    assert response.status_code in [401, 403]
