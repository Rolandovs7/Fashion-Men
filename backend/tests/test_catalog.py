def test_listar_categorias(client, seed_data):
    response = client.get("/categorias")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1
    assert any(c["nombre"] == seed_data["categoria"].nombre for c in data)


def test_obtener_categoria_por_id(client, seed_data):
    cat_id = seed_data["categoria"].id
    response = client.get(f"/categorias/{cat_id}")
    assert response.status_code == 200
    assert response.json()["id"] == cat_id


def test_obtener_categoria_inexistente(client):
    response = client.get("/categorias/99999")
    assert response.status_code == 404


def test_crear_categoria_como_admin(client, admin_headers):
    payload = {
        "nombre": "Pantalones",
        "descripcion": "Pantalones de vestir y casuales"
    }
    response = client.post("/categorias", json=payload, headers=admin_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["nombre"] == payload["nombre"]
    assert "id" in data


def test_crear_categoria_como_cliente_denegado(client, client_headers):
    payload = {
        "nombre": "Zapatos",
        "descripcion": "Calzado elegante"
    }
    response = client.post("/categorias", json=payload, headers=client_headers)
    assert response.status_code == 403


def test_listar_productos(client, seed_data):
    response = client.get("/productos")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1
    assert any(p["nombre"] == seed_data["producto"].nombre for p in data)


def test_obtener_producto_por_id(client, seed_data):
    prod_id = seed_data["producto"].id
    response = client.get(f"/productos/{prod_id}")
    assert response.status_code == 200
    assert response.json()["id"] == prod_id


def test_obtener_producto_inexistente(client):
    response = client.get("/productos/99999")
    assert response.status_code == 404


def test_crear_producto_como_admin(client, admin_headers, seed_data):
    payload = {
        "nombre": "Chaqueta de Cuero",
        "descripcion": "Chaqueta 100% cuero genuino",
        "precio": 199.99,
        "categoria_id": seed_data["categoria"].id
    }
    response = client.post("/productos", json=payload, headers=admin_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["nombre"] == payload["nombre"]
    assert data["precio"] == payload["precio"]


def test_crear_producto_como_cliente_denegado(client, client_headers, seed_data):
    payload = {
        "nombre": "Producto No Permitido",
        "precio": 10.0,
        "categoria_id": seed_data["categoria"].id
    }
    response = client.post("/productos", json=payload, headers=client_headers)
    assert response.status_code == 403
