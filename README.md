# 👔 MenStyle — Plataforma Inteligente de Comercio Electrónico de Moda Masculina

[![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)](https://fastapi.tiangolo.com/)
[![Angular](https://img.shields.io/badge/Angular-DD0031?style=for-the-badge&logo=angular)](https://angular.io/)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql)](https://www.postgresql.org/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)

Plataforma omnicanal de comercio electrónico especializada en **moda masculina** con soporte web, móvil y backend, que integra **Realidad Aumentada** e **Inteligencia Artificial**.

---

## 📋 Tabla de Contenidos

- [Características](#-características)
- [Estado del Proyecto](#-estado-del-proyecto)
- [Stack Tecnológico](#-stack-tecnológico)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Requisitos Previos](#-requisitos-previos)
- [Instalación Paso a Paso](#-instalación-paso-a-paso)
- [Ejecución del Proyecto](#-ejecución-del-proyecto)
- [Despliegue en Producción](#-despliegue-en-producción)
- [Variables de Entorno](#-variables-de-entorno)
- [Endpoints Principales](#-endpoints-principales)
- [Documentación](#-documentación)
- [Equipo](#-equipo)
- [Licencia](#-licencia)

---

## 🎯 Características

### Cliente
- 🛍️ **Catálogo de prendas masculinas** (trajes, camisas, pantalones, accesorios)
- 🔍 **Búsqueda y filtros** por categoría, talla, color, marca
- 📱 **Aplicación web y móvil** multiplataforma
- 📍 **Consulta de disponibilidad** en tiempo real por sucursal
- 📌 **Reserva de prendas** para probarlas en tienda física
- 🪞 **Vestidor virtual** con Realidad Aumentada
- 🤖 **Asistente IA** para recomendaciones personalizadas
- 💳 **Compra digital** con pasarela de pago
- 📦 **Historial de compras**

### Administrador
- 👥 Gestión de usuarios, roles y permisos
- 🏪 Administración de sucursales y ciudades
- 📦 CRUD de productos, categorías, tallas, colores, marcas
- 🎨 Gestión de temporadas y colecciones
- 🚚 Gestión de proveedores
- 📊 **Dashboard** con KPIs ejecutivos
- 📈 **Reportes** de ventas e inventario
- 💰 Gestión de descuentos y promociones

### Encargado de Sucursal
- 📋 Consulta y preparación de reservas
- 📦 Gestión de inventario local
- ✅ Confirmación de entrega de prendas

### Cajero
- 🛒 Punto de venta (POS)
- 💵 Registro de ventas presenciales
- 🧾 Emisión de comprobantes

---

## 📊 Estado del Proyecto

### ✅ Implementado (Fases 1-8)

**Rediseño visual completo** con el sistema "Quiet Editorial Luxury":
- Home con hero editorial, categorías, productos destacados, IA, sucursales.
- Catálogo con filtros (categoría, talla, color), ordenamiento, paginación.
- Detalle de producto con galería, selectores de talla/color, imagen dinámica
  por color, cantidad, agregar al carrito, reservar.
- Carrito de compras + checkout + confirmación.
- Mis pedidos con comprobante y cancelación.
- Login / Registro / Recuperar contraseña con validaciones.
- Reservas + Notificaciones.
- Panel de Administración completo:
  * AdminShell con sidebar + navegación.
  * Catálogo (12 secciones): categorías, productos, variantes, tallas,
    colores, sucursales, proveedores, temporadas, colecciones, tipos de
    prenda, marcas, descuentos.
  * Operaciones (pedidos y reservas).
  * Reportes y estadísticas con Chart.js.
  * Configuración (roles + tipos de pago).
  * Punto de Venta (POS).
  * Inventario con paginación optimizada.
  * Usuarios y Permisos.

**Sistema de diseño:** 12 componentes + barrel (index.ts): alert, badge,
button, empty-state, footer, input, loader, modal, price, select, skeleton,
toast.

**Catálogo de productos:** 21 productos activos, 186 variantes, imágenes
por variante en 3 sucursales.

**IA:** Google Gemini integrado para recomendaciones personalizadas y
asistente virtual con historial multi-turno.

### 🚧 Pendiente

- Realidad Aumentada (probador virtual).
- Pasarela de pago Stripe en producción (sandbox actual).
- Aplicación móvil Flutter (backend listo, frontend mobile parcial).
- Environments dev/prod en Angular (actualmente hardcoded a producción).
- Optimización del bundle (lazy loading).

---

## 🛠️ Stack Tecnológico

| Capa | Tecnología | Versión |
|------|------------|---------|
| **Backend** | Python + FastAPI | 3.12+ / 0.141+ |
| **Frontend Web** | Angular | 21.2 |
| **App Móvil** | Flutter + Dart | 3.16+ |
| **Base de Datos** | PostgreSQL | 16 |
| **ORM** | SQLAlchemy + Alembic | 2.0+ |
| **Estilos** | Tailwind CSS | 4.x |
| **Gráficos** | Chart.js | 4.x |
| **Autenticación** | JWT (python-jose) | - |
| **IA** | Google Gemini (google-genai) | 1.16.1 |
| **Realidad Aumentada** | ARCore / ARKit | (pendiente) |
| **Pagos** | Stripe | Sandbox |
| **Control de Versiones** | Git + GitHub | - |

---

## 📁 Estructura del Proyecto

```
MenStyle/
├── backend/                    # API REST en FastAPI
│   ├── app/
│   │   ├── api/routes/        # Endpoints de la API
│   │   ├── core/              # Configuración, DB, seguridad
│   │   ├── models/            # Modelos SQLAlchemy
│   │   ├── schemas/           # Esquemas Pydantic
│   │   ├── services/          # Lógica de negocio
│   │   └── main.py            # Punto de entrada
│   ├── migrations/            # Migraciones Alembic
│   ├── tests/                 # Pruebas con pytest
│   ├── requirements.txt
│   ├── alembic.ini
│   └── .env.example
│
├── frontend/                   # Aplicación web Angular
│   ├── src/
│   │   ├── app/
│   │   │   ├── core/          # Servicios, guards
│   │   │   ├── pages/         # Vistas por ruta
│   │   │   └── shared/        # Componentes reutilizables
│   │   └── main.ts
│   ├── package.json
│   └── angular.json
│
├── mobile/                     # App móvil Flutter
│   ├── lib/
│   │   ├── screens/           # Pantallas
│   │   ├── services/          # HTTP + lógica
│   │   ├── models/            # Modelos
│   │   └── widgets/           # Componentes
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── docs/                       # Documentación PUDS + UML
│   ├── 01_perfil/
│   ├── 02_marco_teorico/
│   ├── 03_modelo_negocio/
│   ├── 04_captura_requisitos/
│   ├── 05_analisis/
│   ├── 06_diseno/
│   ├── 07_implementacion/
│   ├── 08_pruebas/
│   ├── 09_anexos/
│   └── fundamentacion/
│
├── .gitignore
├── README.md
└── setup.sh
```

---

## ✅ Requisitos Previos

Antes de comenzar, instala las siguientes herramientas:

| Herramienta | Versión Mínima | Cómo verificar | Instalación |
|-------------|----------------|----------------|-------------|
| **Python** | 3.12+ | `python3 --version` | [python.org](https://www.python.org/downloads/) |
| **Node.js** | 20+ | `node --version` | [nodejs.org](https://nodejs.org/) |
| **Angular CLI** | 17+ | `ng version` | `npm install -g @angular/cli` |
| **Flutter SDK** | 3.16+ | `flutter --version` | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| **PostgreSQL** | 16+ | `psql --version` | [postgresql.org](https://www.postgresql.org/download/) |
| **Git** | 2.40+ | `git --version` | [git-scm.com](https://git-scm.com/) |

---

## 🚀 Instalación Paso a Paso

### Paso 1: Clonar el Repositorio

```bash
git clone https://github.com/Rolandovs7/Fashion-Men.git
cd Fashion-Men
```

### Paso 2: Configurar la Base de Datos PostgreSQL

**Opción A: PostgreSQL local**

```bash
# Abrir PostgreSQL
sudo -u postgres psql

# Dentro de psql, ejecutar:
CREATE DATABASE menstyle_db;
CREATE USER menstyle_user WITH PASSWORD 'menstyle123';
GRANT ALL PRIVILEGES ON DATABASE menstyle_db TO menstyle_user;
ALTER USER menstyle_user CREATEDB;
\q
```

**Opción B: PostgreSQL con Docker** (más fácil)

```bash
docker run -d \
  --name menstyle-postgres \
  -e POSTGRES_USER=menstyle_user \
  -e POSTGRES_PASSWORD=menstyle123 \
  -e POSTGRES_DB=menstyle_db \
  -p 5432:5432 \
  postgres:16
```

### Paso 3: Configurar el Backend (FastAPI)

```bash
# 1. Desde la raíz del proyecto, crear entorno virtual
python3 -m venv .venv

# 2. Activar entorno virtual
source .venv/bin/activate          # Linux/macOS
# .venv\Scripts\activate           # Windows

# 3. Ir a la carpeta del backend
cd backend

# 4. Instalar dependencias
pip install --upgrade pip
pip install -r requirements.txt

# 5. Copiar archivo de configuración
cp .env.example .env

# 6. Editar .env con tus credenciales
nano .env
```

**Contenido de `backend/.env`:**

```env
DATABASE_URL=postgresql://menstyle_user:menstyle123@localhost:5432/menstyle_db
SECRET_KEY=cambia-esta-clave-por-una-larga-y-segura
GEMINI_API_KEY=opcional-tu-api-key-de-google-ai-studio
STRIPE_SECRET_KEY=opcional-tu-secret-key-de-stripe
STRIPE_PUBLISHABLE_KEY=opcional-tu-publishable-key-de-stripe
```

```bash
# 7. Ejecutar migraciones de la BD
alembic upgrade head

# 8. (Opcional) Crear usuario admin
python seed_admin.py
```

### Paso 4: Configurar el Frontend (Angular)

```bash
# Ir a la carpeta del frontend
cd frontend

# Instalar dependencias
npm install

# Verificar que compila
ng build
```

### Paso 5: Configurar la App Móvil (Flutter)

```bash
# Ir a la carpeta mobile
cd mobile

# Verificar que Flutter está instalado
flutter doctor

# Descargar dependencias
flutter pub get
```

---

## ▶️ Ejecución del Proyecto

Necesitas **3 terminales** para ejecutar todo el stack.

### Terminal 1: Backend (FastAPI)

```bash
cd backend
source ../.venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Acceso:**
- API: <http://localhost:8000>
- Swagger UI: <http://localhost:8000/docs>
- ReDoc: <http://localhost:8000/redoc>

### Terminal 2: Frontend Web (Angular)

```bash
cd frontend
ng serve
```

**Acceso:** <http://localhost:4200>

### Terminal 3: App Móvil (Flutter)

```bash
cd mobile

# Ver dispositivos disponibles
flutter devices

# Ejecutar en Chrome (rápido)
flutter run -d chrome

# O en emulador/dispositivo
flutter run
```

---

## 🌐 Despliegue en Producción

| Servicio | URL | Plataforma |
|----------|-----|------------|
| **Frontend Web** | https://menstyle-web-0de9.onrender.com | Render Static |
| **Backend API** | https://menstyle-api-n77g.onrender.com | Render Web |
| **Swagger UI** | https://menstyle-api-n77g.onrender.com/docs | - |
| **PostgreSQL** | (Render PostgreSQL) | Render |

### Credenciales de Prueba

**Administrador:**
- Email: rolando@gmail.com
- Password: 123456

**Cliente:**
- Email: cliente@ejemplo.com
- Password: cliente123

---

## 🔑 Variables de Entorno

### Backend (`backend/.env`)

| Variable | Descripción | Obligatorio |
|----------|-------------|-------------|
| `DATABASE_URL` | URL de conexión PostgreSQL | ✅ Sí |
| `SECRET_KEY` | Clave para firmar JWT | ✅ Sí |
| `GEMINI_API_KEY` | API key de Google Gemini | 🟡 Opcional |
| `STRIPE_SECRET_KEY` | Secret key de Stripe | 🟡 Opcional |
| `STRIPE_PUBLISHABLE_KEY` | Publishable key de Stripe | 🟡 Opcional |

---

## 🌐 Endpoints Principales

### Autenticación
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/auth/register` | Registrar cliente |
| POST | `/api/auth/login` | Iniciar sesión |
| GET | `/api/auth/me` | Obtener usuario actual |

### Catálogo
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/productos/` | Listar productos |
| GET | `/api/productos/{id}` | Detalle de producto |
| GET | `/api/categorias/` | Listar categorías |

### Variantes
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/variantes/producto/{id}` | Variantes de un producto con stock |
| GET | `/api/inventario/detallado` | Inventario paginado enriquecido |

### Reservas
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/reservas/` | Crear reserva |
| GET | `/api/reservas/me` | Mis reservas |

### Pedidos y Pagos
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/pedidos/` | Crear pedido |
| GET | `/api/pedidos/me` | Mis pedidos |
| PUT | `/api/pedidos/{id}` | Actualizar estado del pedido |
| DELETE | `/api/pedidos/{id}` | Cancelar pedido |
| POST | `/api/pagos/` | Procesar pago |

### IA
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/ia/recomendar` | Recomendaciones personalizadas |
| POST | `/api/ia/chat` | Asistente virtual |
| GET | `/api/ia/tendencias` | Productos en tendencia |

### Reportes
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/reportes/dashboard` | KPIs ejecutivos |
| GET | `/api/reportes/productos-top` | Productos más vendidos |

> 📖 **Documentación completa:** <http://localhost:8000/docs>

---

## 🧪 Testing

### Backend (pytest)

```bash
cd backend
source ../.venv/bin/activate
pytest -v
```

### Frontend (Angular)

```bash
cd frontend
ng test
```

### Mobile (Flutter)

```bash
cd mobile
flutter test
```

---

## 📚 Documentación

La documentación completa del proyecto sigue el **Proceso Unificado de Desarrollo (PUDS)** y **UML 2.5+**:

| Sección | Ubicación |
|---------|-----------|
| **1. Perfil** | [`docs/01_perfil/`](docs/01_perfil/) |
| **2. Marco Teórico** | [`docs/02_marco_teorico/`](docs/02_marco_teorico/) |
| **3. Modelo de Negocio** | [`docs/03_modelo_negocio/`](docs/03_modelo_negocio/) |
| **4. Captura de Requisitos** | [`docs/04_captura_requisitos/`](docs/04_captura_requisitos/) |
| **5. Análisis** | [`docs/05_analisis/`](docs/05_analisis/) |
| **6. Diseño** | [`docs/06_diseno/`](docs/06_diseno/) |
| **7. Implementación** | [`docs/07_implementacion/`](docs/07_implementacion/) |
| **8. Pruebas** | [`docs/08_pruebas/`](docs/08_pruebas/) |
| **9. Anexos** | [`docs/09_anexos/`](docs/09_anexos/) |
| **Fundamentación Teórica** | [`docs/fundamentacion/`](docs/fundamentacion/) |

### Diagramas UML

Todos los diagramas están en formato **PlantUML** (`.puml`) y son **editables**:
- Casos de Uso
- Clases (Análisis + Diseño)
- Secuencia
- Comunicación
- Estados
- Actividad
- Componentes
- Despliegue
- Paquetes
- Navegación
- Red
- Tiempo

Para visualizarlos, se recomienda instalar la extensión **PlantUML** en VS Code.

---

## 🐛 Solución de Problemas

### Error: `ModuleNotFoundError: No module named 'app'`

**Causa:** No estás en la carpeta correcta.
**Solución:** Ejecuta los comandos desde `backend/`, no desde la raíz.

### Error: `relation "usuarios" does not exist`

**Causa:** No aplicaste las migraciones.
**Solución:**
```bash
cd backend
alembic upgrade head
```

### Error: `Connection refused` en PostgreSQL

**Causa:** PostgreSQL no está corriendo.
**Solución:**
```bash
# Linux
sudo systemctl start postgresql

# macOS
brew services start postgresql

# Docker
docker start menstyle-postgres
```

### Error: `flutter: command not found`

**Causa:** Flutter no está en el PATH.
**Solución:** Agrega Flutter al PATH:
```bash
export PATH="$PATH:$HOME/development/flutter/bin"
```

---

## 👥 Equipo

| Estudiante | Registro | Rol |
|------------|----------|-----|
| **Rolando Velasco Soliz** | 223044768 | Backend Developer |
| **Jimena Jahuira Poma** | 223042951 | Frontend Developer |

**Materia:** Sistemas de Información II
**Docente:** MSc. Ing. Angélica Garzón Cuéllar
**Sigla:** INF412-SA
**Grupo:** #23
**Semestre:** 2-2026

---

## 📄 Licencia

Este proyecto está bajo la **Licencia MIT** — ver el archivo [LICENSE](LICENSE) para más detalles.

---

## 🙏 Agradecimientos

Proyecto desarrollado como parte del curso **Sistemas de Información II** aplicando el **Proceso Unificado de Desarrollo de Software (PUDS)** y **UML 2.5+**.

---

**⭐ Si este proyecto te resultó útil, dale una estrella en GitHub.**

**Última actualización:** Septiembre 2026