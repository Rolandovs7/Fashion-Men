def test_listar_inventario(client, seed_data):
    response = client.get("/inventario")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1
    assert any(i["variante_id"] == seed_data["variante"].id for i in data)


def test_obtener_inventario_por_id(client, seed_data):
    inv_id = seed_data["inventario"].id
    response = client.get(f"/inventario/{inv_id}")
    assert response.status_code == 200
    assert response.json()["id"] == inv_id


def test_obtener_inventario_inexistente(client):
    response = client.get("/inventario/99999")
    assert response.status_code == 404


def test_crear_inventario_admin(client, admin_headers, db_session, seed_data):
    from app.models.branch import Sucursal
    from app.models.product_variant import ProductoVariante

    nueva_sucursal = Sucursal(nombre="Sucursal Norte", direccion="Av. Norte 456", ciudad="Santiago", activo=True)
    db_session.add(nueva_sucursal)

    nueva_variante = ProductoVariante(
        producto_id=seed_data["producto"].id,
        talla_id=seed_data["talla"].id,
        color_id=seed_data["color"].id,
        activo=True
    )
    db_session.add(nueva_variante)
    db_session.commit()
    db_session.refresh(nueva_sucursal)
    db_session.refresh(nueva_variante)

    payload = {
        "variante_id": nueva_variante.id,
        "sucursal_id": nueva_sucursal.id,
        "cantidad": 100,
        "cantidad_reservada": 0
    }
    response = client.post("/inventario", json=payload, headers=admin_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["cantidad"] == payload["cantidad"]




def test_crear_inventario_cliente_denegado(client, client_headers, seed_data):
    payload = {
        "variante_id": seed_data["variante"].id,
        "sucursal_id": seed_data["sucursal"].id,
        "cantidad": 20
    }
    response = client.post("/inventario", json=payload, headers=client_headers)
    assert response.status_code == 403


def test_actualizar_inventario_admin(client, admin_headers, seed_data):
    inv_id = seed_data["inventario"].id
    payload = {
        "cantidad": 75
    }
    response = client.put(f"/inventario/{inv_id}", json=payload, headers=admin_headers)
    assert response.status_code == 200
    assert response.json()["cantidad"] == 75
