Plataforma de comercio electrónico especializada en **moda masculina**, con soporte web (Angular), móvil (Flutter) y backend (FastAPI).

## 🎯 Características Principales

- 🛍️ Catálogo de prendas masculinas (trajes, camisas, pantalones, accesorios)
- 📱 App web + móvil multiplataforma
- 🪞 Vestidores virtuales con Realidad Aumentada
- 🤖 Asistente IA para recomendaciones
- 📦 Gestión de inventario multi-sucursal
- 💳 Pagos con pasarela electrónica

## 🛠️ Stack Tecnológico

| Capa | Tecnología |
|------|------------|
| Backend | Python + FastAPI |
| Frontend Web | Angular 17+ |
| App Móvil | Flutter + Dart |
| Base de Datos | PostgreSQL 16 |
| IA | Modelo/servicio vía API |
| Realidad Aumentada | ARCore / ARKit |

## 📁 Estructura del Proyecto

MenStyle/
├── backend/ # API REST en FastAPI
├── frontend/ # Aplicación web Angular
├── mobile/ # App móvil Flutter
├── docs/ # Documentación y diagramas UML
├── .gitignore
├── README.md
└── setup.sh


## 🚀 Instalación Rápida

### Requisitos previos
- Python 3.12+
- Node.js 20+
- Flutter 3.16+
- PostgreSQL 16+

### Backend
```bash
# Crear entorno virtual en la raíz
python3 -m venv .venv
source .venv/bin/activate

# Instalar dependencias
cd backend
pip install -r requirements.txt

# Configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales

# Ejecutar migraciones
alembic upgrade head

# Levantar servidor
uvicorn app.main:app --reload

API disponible en: http://localhost:8000
Documentación: http://localhost:8000/docs,

Frontend
cd frontend
npm install
ng serve
Disponible en: http://localhost:4200

Mobile
cd mobile
flutter pub get
flutter run

📖 Documentación

    Diagramas UML — Casos de uso, clases, secuencia

    Manual de Usuario

👥 Equipo

    [Rolando Velasco Soliz - 223044768]
    [Jimena Jahuira Poma - 223042951]