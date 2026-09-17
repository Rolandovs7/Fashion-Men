# 🔗 Matriz de Trazabilidad - MenStyle

Este documento mapea **Casos de Uso (CU)** con **Requisitos Funcionales (RF)** del examen, y con los **archivos/endpoints** que los implementan.

## 📋 Tabla General (33 casos de uso)

| CU | Nombre | Web | Móvil | RF(s) | Endpoint | Archivo backend | Estado |
|----|--------|-----|-------|-------|----------|-----------------|--------|
| CU01 | Administrar Inicio de Sesión | ✓ | ✓ | RF01 | POST /api/auth/login | auth.py | ✅ |
| CU02 | Administrar Cierre de Sesión | ✓ | ✓ | RF01 | (stateless) | auth.py | ✅ |
| CU03 | Registrar Usuario | ✓ | ✓ | RF01 | POST /api/auth/register | auth.py | ✅ |
| CU04 | Gestionar Usuarios | ✓ | | RF02 | /api/users | users.py | ✅ |
| CU05 | Gestionar Roles | ✓ | | RF02 | /api/roles | roles.py | ✅ |
| CU06 | Asignar Permisos | ✓ | | RF02 | /api/permissions | permissions.py | ✅ |
| CU07 | Gestionar Productos | ✓ | | RF04 | /api/products | products.py | ✅ |
| CU08 | Gestionar Tipo de Prenda | ✓ | | RF05 | /api/garment-types | garment_types.py | ✅ |
| CU09 | Gestionar Descuentos | ✓ | | RF05 | /api/discounts | discounts.py | ✅ |
| CU10 | Gestionar Marcas | ✓ | | RF04 | /api/brands | brands.py | ✅ |
| CU11 | Gestionar Tallas | ✓ | | RF05 | /api/sizes | sizes.py | ✅ |
| CU12 | Gestionar Colores | ✓ | | RF05 | /api/colors | colors.py | ✅ |
| CU13 | Gestionar Imágenes | ✓ | | RF04 | (parte de productos) | products.py | 🚧 |
| CU14 | Administrar Catálogo | ✓ | ✓ | RF07 | GET /api/products | products.py | ✅ |
| CU15 | Administrar Inventario | ✓ | | RF21 RF22 | /api/inventory | inventory.py | ✅ |
| CU16 | Gestionar Categorías | ✓ | | RF05 | /api/categories | categories.py | ✅ |
| CU17 | Gestionar Sucursales | ✓ | | RF03 | /api/branches | branches.py | ✅ |
| CU18 | Administrar Venta de Producto | ✓ | | RF17 | POST /api/orders | orders.py | ✅ |
| CU19 | Administrar Tipo de Pago | ✓ | ✓ | RF18 RF19 | /api/payment-types | payment_types.py payments.py | ✅ |
| CU20 | Realizar Nota de Venta | ✓ | | RF17 | POST /api/orders | orders.py | ✅ |
| CU21 | Gestionar Pedido | ✓ | ✓ | RF15 RF16 | /api/orders | orders.py | ✅ |
| CU22 | Administrar Carrito de Compra | ✓ | ✓ | RF14 | /api/cart | cart.py | ✅ |
| CU23 | Realizar Probador Virtual | ✓ | ✓ | RF13 | (Flutter) | mobile/lib/ar/ | ❌ FALTA |
| CU24 | Gestionar Reservas | ✓ | ✓ | RF09-RF12 | /api/reservations | reservations.py | ✅ |
| CU25 | Consultar Disponibilidad | ✓ | ✓ | RF08 | GET /api/inventory | inventory.py | ✅ |
| CU26 | Gestionar Proveedores | ✓ | | RF06 | /api/suppliers | suppliers.py | ✅ |
| CU27 | Gestionar Temporadas | ✓ | | RF23 | /api/seasons | seasons.py | ✅ |
| CU28 | Gestionar Colecciones | ✓ | | RF23 | /api/collections | collections.py | ✅ |
| CU29 | Visualizar Dashboard | ✓ | | RF24 | /api/reports/dashboard | reports.py | 🚧 |
| CU30 | Generar Reportes | ✓ | | RF24 | /api/reports | reports.py | ❌ FALTA |
| CU31 | Recibir Recomendaciones IA | ✓ | ✓ | RF25 | POST /api/ia/recomendar | ia.py | ❌ FALTA |
| CU32 | Interactuar Asistente Virtual | ✓ | ✓ | RF25 | POST /api/ia/chat | ia.py | ❌ FALTA |
| CU33 | Gestionar Historial de Compras | ✓ | ✓ | RF15 RF16 | GET /api/orders/me | orders.py | 🚧 |

## 🎯 Convención de encabezados en código

Cada archivo del backend tendrá al inicio:

```python
# ============================================================
# TRAZABILIDAD MENSTYLE
# CU: CUXX - Nombre del caso de uso
# RF: RFXX - Descripción del requisito funcional
# ENDPOINT: METODO /api/ruta
# CAPA: Backend FastAPI
# ============================================================
```

## 📊 Estado General

| Categoría | Cantidad | % |
|-----------|----------|---|
| ✅ Implementados | 26 | 79% |
| 🚧 Por completar | 4 | 12% |
| ❌ Faltantes | 3 | 9% |

### Prioridades críticas (obligatorios del examen)

- 🔴 CU23 - Realizar Probador Virtual (RF13)
- 🔴 CU30 - Generar Reportes (RF24)
- 🔴 CU31 - Recibir Recomendaciones IA (RF25)
- 🔴 CU32 - Interactuar con Asistente Virtual (RF25)
- 🔴 CU19 - Ampliar con pasarela Stripe real (RF19)