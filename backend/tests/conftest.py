import os
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

# Usar SQLite en memoria aislado para pruebas
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)

TestingSessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

from app.core.database import Base
from app.main import app
from app.core.dependencies import obtener_db
from app.api.routes.auth import obtener_db as auth_obtener_db
from app.core.security import obtener_password_hash, crear_access_token
from app.models.user import Usuario
from app.models.branch import Sucursal
from app.models.size import Talla
from app.models.color import Color
from app.models.category import Categoria
from app.models.product import Producto
from app.models.product_variant import ProductoVariante
from app.models.inventory import Inventario


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[obtener_db] = override_get_db
app.dependency_overrides[auth_obtener_db] = override_get_db


@pytest.fixture(scope="session", autouse=True)
def setup_test_db():
    """Crea la estructura de tablas completa al iniciar las pruebas y elimina al finalizar."""
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def db_session():
    """Entrega una sesión limpia para operaciones directas en BD durante un test."""
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture
def client():
    """TestClient para peticiones a FastAPI."""
    with TestClient(app) as c:
        yield c


@pytest.fixture
def admin_user(db_session):
    """Crea y retorna un usuario administrador."""
    admin = db_session.query(Usuario).filter(Usuario.email == "admin@menstyle.com").first()
    if not admin:
        admin = Usuario(
            nombre="Admin",
            apellido="MenStyle",
            email="admin@menstyle.com",
            password_hash=obtener_password_hash("admin123"),
            rol="administrador",
            activo=True
        )
        db_session.add(admin)
        db_session.commit()
        db_session.refresh(admin)
    return admin


@pytest.fixture
def client_user(db_session):
    """Crea y retorna un usuario cliente."""
    usuario = db_session.query(Usuario).filter(Usuario.email == "cliente@menstyle.com").first()
    if not usuario:
        usuario = Usuario(
            nombre="Juan",
            apellido="Pérez",
            email="cliente@menstyle.com",
            password_hash=obtener_password_hash("cliente123"),
            rol="cliente",
            activo=True
        )
        db_session.add(usuario)
        db_session.commit()
        db_session.refresh(usuario)
    return usuario


@pytest.fixture
def admin_headers(admin_user):
    """Headers con Bearer JWT token para Administrador."""
    token = crear_access_token({"sub": str(admin_user.id), "rol": admin_user.rol})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def client_headers(client_user):
    """Headers con Bearer JWT token para Cliente."""
    token = crear_access_token({"sub": str(client_user.id), "rol": client_user.rol})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def seed_data(db_session):
    """Poblar entidades base: Sucursal, Talla, Color, Categoria, Producto, ProductoVariante e Inventario."""
    # Sucursal
    sucursal = db_session.query(Sucursal).filter(Sucursal.nombre == "Sucursal Central").first()
    if not sucursal:
        sucursal = Sucursal(
            nombre="Sucursal Central",
            direccion="Av. Principal 123",
            ciudad="Santiago",
            telefono="123456789",
            activo=True
        )
        db_session.add(sucursal)

    # Talla
    talla = db_session.query(Talla).filter(Talla.nombre == "M").first()
    if not talla:
        talla = Talla(nombre="M", activo=True)
        db_session.add(talla)

    # Color
    color = db_session.query(Color).filter(Color.nombre == "Negro").first()
    if not color:
        color = Color(nombre="Negro", codigo_hex="#000000", activo=True)
        db_session.add(color)

    # Categoria
    categoria = db_session.query(Categoria).filter(Categoria.nombre == "Camisas").first()
    if not categoria:
        categoria = Categoria(nombre="Camisas", descripcion="Camisas de vestir", activo=True)
        db_session.add(categoria)


    db_session.commit()
    db_session.refresh(sucursal)
    db_session.refresh(talla)
    db_session.refresh(color)
    db_session.refresh(categoria)

    # Producto
    producto = db_session.query(Producto).filter(Producto.nombre == "Camisa Formal Negra").first()
    if not producto:
        producto = Producto(
            nombre="Camisa Formal Negra",
            descripcion="Camisa elegante 100% algodón",
            precio=49.99,
            categoria_id=categoria.id,
            activo=True
        )
        db_session.add(producto)
        db_session.commit()
        db_session.refresh(producto)

    # ProductoVariante
    variante = db_session.query(ProductoVariante).filter(
        ProductoVariante.producto_id == producto.id,
        ProductoVariante.talla_id == talla.id,
        ProductoVariante.color_id == color.id
    ).first()

    if not variante:
        variante = ProductoVariante(
            producto_id=producto.id,
            talla_id=talla.id,
            color_id=color.id,
            activo=True
        )
        db_session.add(variante)
        db_session.commit()
        db_session.refresh(variante)

    # Inventario
    inventario = db_session.query(Inventario).filter(
        Inventario.variante_id == variante.id,
        Inventario.sucursal_id == sucursal.id
    ).first()

    if not inventario:
        inventario = Inventario(
            variante_id=variante.id,
            sucursal_id=sucursal.id,
            cantidad=50,
            cantidad_reservada=0
        )
        db_session.add(inventario)
        db_session.commit()
        db_session.refresh(inventario)

    return {
        "sucursal": sucursal,
        "talla": talla,
        "color": color,
        "categoria": categoria,
        "producto": producto,
        "variante": variante,
        "inventario": inventario
    }
