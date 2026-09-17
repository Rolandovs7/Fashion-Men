def test_registro_usuario_exitoso(client):
    payload = {
        "nombre": "Carlos",
        "apellido": "Mendoza",
        "email": "carlos.mendoza@example.com",
        "password": "Password123!"
    }
    response = client.post("/auth/registro", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == payload["email"]
    assert data["nombre"] == payload["nombre"]
    assert data["activo"] is True
    assert "id" in data



def test_registro_usuario_email_duplicado(client, client_user):
    payload = {
        "nombre": "Duplicado",
        "apellido": "Prueba",
        "email": client_user.email,
        "password": "Password123!"
    }
    response = client.post("/auth/registro", json=payload)
    assert response.status_code == 400
    assert "correo electrónico ya está registrado" in response.json()["detail"]


def test_login_exitoso(client, client_user):
    payload = {
        "email": client_user.email,
        "password": "cliente123"
    }
    response = client.post("/auth/login", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


def test_login_contrasena_incorrecta(client, client_user):
    payload = {
        "email": client_user.email,
        "password": "wrongpassword"
    }
    response = client.post("/auth/login", json=payload)
    assert response.status_code == 401
    assert "Correo o contraseña incorrectos" in response.json()["detail"]


def test_obtener_me_autenticado(client, client_headers, client_user):
    response = client.get("/auth/me", headers=client_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == client_user.email
    assert data["id"] == client_user.id


def test_obtener_me_sin_token(client):
    response = client.get("/auth/me")
    assert response.status_code in [401, 403]


def test_ruta_admin_con_admin(client, admin_headers):
    response = client.get("/auth/admin", headers=admin_headers)
    assert response.status_code == 200
    assert response.json()["mensaje"] == "Acceso permitido"


def test_ruta_admin_con_cliente(client, client_headers):
    response = client.get("/auth/admin", headers=client_headers)
    assert response.status_code == 403
    assert "No tienes permisos" in response.json()["detail"]
