def test_listar_notificaciones(client, client_headers, seed_data):
    # Generar al menos una notificación (al crear un pedido)
    client.delete("/carrito", headers=client_headers)
    client.post("/carrito/items", json={"variante_id": seed_data["variante"].id, "cantidad": 1}, headers=client_headers)
    client.post("/pedidos", json={"sucursal_id": seed_data["sucursal"].id}, headers=client_headers)

    response = client.get("/notificaciones", headers=client_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1


def test_listar_notificaciones_no_leidas(client, client_headers):
    response = client.get("/notificaciones/no-leidas", headers=client_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert all(not n["leida"] for n in data)


def test_marcar_notificacion_como_leida(client, client_headers):
    notificaciones = client.get("/notificaciones", headers=client_headers).json()
    if notificaciones:
        notif_id = notificaciones[0]["id"]
        response = client.put(f"/notificaciones/{notif_id}/leer", headers=client_headers)
        assert response.status_code == 200
        assert response.json()["leida"] is True
