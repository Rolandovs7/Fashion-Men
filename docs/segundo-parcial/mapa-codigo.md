# 🗺️ Mapa de Código — Fashion Men (Segundo Parcial)

**Archivo:** `docs/segundo-parcial/mapa-codigo.md`
**Alcance de esta versión:** CU01 · CU02 · CU03

## 📌 Cómo se lee este documento

Para cada Caso de Uso (CU) se indica:

| Sección | Contenido |
|---------|-----------|
| **Modelos / tablas del backend** | Tablas SQLAlchemy involucradas y sus atributos. |
| **Rutas del backend** | Endpoints REST consumidos por el CU. |
| **Pantallas del frontend** | Pantallas del Angular que implementan el CU. |
| **Pantallas del mobile** | Pantallas del Flutter que implementan el CU. |

Si algún componente **no existe**, se escribe **PENDIENTE**.

---

# CU01 — Registrar empresa y contratar plan

**RF asociado:** RF01 — Gestión Multitenant y Empresas
**Actor principal:** Administrador
**Estado general:** ⚠️ Parcial

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Empresa` | `empresas` | `backend/app/models/saas.py` | `id` (Integer, PK, indexed) · `nombre` (String(150), unique, nullable=False) · `fecha_registro` (DateTime, default UTC, nullable=False) · `activo` (Boolean, default true, nullable=False) |
| `Plan` | `planes` | `backend/app/models/saas.py` | `id` (Integer, PK, indexed) · `nombre` (String(50), unique, nullable=False) · `max_sucursales` (Integer, default 2, nullable=False) · `permite_ia` (Boolean, default false, nullable=False) · `permite_offline` (Boolean, default false, nullable=False) |
| `Suscripcion` | `suscripciones` | `backend/app/models/saas.py` | `id` (Integer, PK, indexed) · `empresa_id` (Integer, FK `empresas.id`, nullable=False, indexed) · `plan_id` (Integer, FK `planes.id`, nullable=False, indexed) · `fecha_inicio` (DateTime, default UTC, nullable=False) · `fecha_fin` (DateTime, nullable) · `estado` (String(20), default "activo", nullable=False) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| POST | `/api/auth/registro` | `backend/app/api/routes/auth.py` | ✅ Existente — asigna empresa por defecto (tenant) al registrar un cliente |
| POST | `/api/auth/login` | `backend/app/api/routes/auth.py` | ✅ Existente — emite JWT con `empresa_id` |
| POST | `/api/sucursales` | `backend/app/api/routes/branches.py` | ✅ Existente — valida límite de sucursales según plan activo (RN-SaaS-01) |
| — | Seed SaaS: `backend/seed_saas.py` | — | ✅ Existente — crea planes, empresas y suscripciones de ejemplo |

| Necesidad del CU | Estado |
|------------------|--------|
| Registrar empresa (alta de tenant) | ❌ PENDIENTE |
| Crear plan / contratar plan / crear suscripción | ❌ PENDIENTE |

## 3. Pantallas del frontend

- **Estado:** ❌ PENDIENTE

No existe pantalla de registro de empresa ni de selección/contratación de plan.
La pantalla `frontend/src/app/pages/admin-configuracion` solo maneja las pestañas
**roles** y **tipos de pago** (`type Pestana = 'roles' | 'tipos-pago'`).

## 4. Pantallas del mobile

- **Estado:** ❌ PENDIENTE

No existe pantalla móvil de registro de empresa ni de planes/suscripciones.

---

# CU02 — Gestionar suscripción

**RF asociado:** RF01 — Gestión Multitenant y Empresas
**Actor principal:** Administrador
**Estado general:** ❌ PENDIENTE

## 1. Modelos / tablas del backend

| Modelo | Tabla | Atributos |
|--------|-------|-----------|
| `Suscripcion` | `suscripciones` | `id` · `empresa_id` (FK `empresas.id`) · `plan_id` (FK `planes.id`) · `fecha_inicio` (DateTime) · `fecha_fin` (DateTime, nullable) · `estado` (String(20), default "activo") |
| `Plan` | `planes` | `id` · `nombre` (String(50), unique) · `max_sucursales` (Integer, default 2) · `permite_ia` (Boolean) · `permite_offline` (Boolean) |

## 2. Rutas del backend

- **Estado:** ❌ PENDIENTE

No existen endpoints REST para gestionar suscripciones (listar / crear / cambiar plan / cancelar).
La única ruta que consume la suscripción y al plan es:

- `POST /api/sucursales` — `backend/app/api/routes/branches.py` — valida el límite de sucursales
  del plan activo de la empresa (RN-SaaS-01).

## 3. Pantallas del frontend

- **Estado:** ❌ PENDIENTE

No existe pantalla ni servicio de frontend para planes/suscripciones.

## 4. Pantallas del mobile

- **Estado:** ❌ PENDIENTE

No existe pantalla ni servicio móvil para planes/suscripciones.

---

# CU03 — Iniciar sesión

**RF asociado:** RF01 — Gestión Multitenant y Empresas
**Actor principal:** Cliente, Administrador
**Estado general:** ✅ IMPLEMENTADO

## 1. Modelos / tablas del backend

| Modelo | Tabla | Atributos |
|--------|-------|-----------|
| `Usuario` | `usuarios` | `id` (Integer, PK, indexed) · `nombre` (String(100), nullable=False) · `apellido` (String(100), nullable=False) · `email` (String(150), unique, indexed, nullable=False) · `password_hash` (String(255), nullable=False) · `activo` (Boolean, default true, nullable=False) · `rol` (String(30), default "cliente", nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=True, indexed) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `fecha_creacion` (DateTime, default UTC, nullable=False) |

Además, el **JWT** emitido por `backend/app/core/security.py` (HS256, exp 60 min) incluye:
`sub` (email), `rol` y `empresa_id`.

## 2. Rutas del backend (`/api/auth`)

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| POST | `/api/auth/login` | `backend/app/api/routes/auth.py` | ✅ Implementado — rate limit 5/min por IP |
| POST | `/api/auth/registro` | `backend/app/api/routes/auth.py` | ✅ Implementado — asigna empresa por defecto |
| GET | `/api/auth/me` | `backend/app/api/routes/auth.py` | ✅ Implementado — obtiene usuario autenticado |
| GET | `/api/auth/admin` | `backend/app/api/routes/auth.py` | ✅ Implementado — solo administrador |
| POST | `/api/auth/forgot-password` | `backend/app/api/routes/auth.py` | ✅ Implementado — recupera contraseña |
| POST | `/api/auth/reset-password` | `backend/app/api/routes/auth.py` | ✅ Implementado — resetea contraseña |

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/login` | `/login` | ✅ Implementado |
| `pages/registro` | `/registro` | ✅ Implementado |
| `pages/forgot-password` | `/forgot-password` | ✅ Implementado |
| `pages/reset-password` | `/reset-password` | ✅ Implementado |
| Servicio `core/services/auth.service.ts` | `frontend/src/app/core/services/auth.service.ts` | ✅ Implementado |
| Guard `core/guards/auth.guard.ts` | `frontend/src/app/core/guards/auth.guard.ts` | ✅ Implementado |
| Logout `shared/header/header.ts` | `frontend/src/app/shared/header/header.ts` | ✅ Implementado (local) |

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/login_page.dart` | `mobile/lib/screens/login_page.dart` | ✅ Implementado |
| `screens/registro_page.dart` | `mobile/lib/screens/registro_page.dart` | ✅ Implementado |
| Servicio `services/auth_service.dart` | `mobile/lib/services/auth_service.dart` | ✅ Implementado |
| Navegación inicial `main.dart` | `mobile/lib/main.dart` | ✅ Implementado |

**Flujo:** `POST /api/auth/login` → guarda `access_token` → `GET /api/auth/me` → redirige
(`/inicio` en web, `AdminCatalogoPage` o `MainShell` en mobile).

---

## 📊 Resumen de estado — CU01 · CU02 · CU03

| CU | Nombre | Modelos backend | Rutas backend | Frontend | Mobile | Estado |
|----|--------|-----------------|---------------|----------|--------|--------|
| CU01 | Registrar empresa y contratar plan | ✅ Empresa / Plan / Suscripcion | ⚠️ Seed + validaciones · ❌ alta de empresa/plan | ❌ PENDIENTE | ❌ PENDIENTE | ⚠️ Parcial |
| CU02 | Gestionar suscripción | ✅ Suscripcion / Plan | ❌ PENDIENTE | ❌ PENDIENTE | ❌ PENDIENTE | ❌ PENDIENTE |
| CU03 | Iniciar sesión | ✅ Usuario + JWT | ✅ Implementado | ✅ Implementado | ✅ Implementado | ✅ Implementado |

---

**Versión:** 1.0
**Fecha:** 31/10/2026

---

# CU04 — Gestionar usuarios y roles

**RF asociado:** RF02 — Gestionar usuarios y roles
**Actor principal:** Administrador
**Estado general:** ✅ IMPLEMENTADO

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Usuario` | `usuarios` | `backend/app/models/user.py` | `id` (Integer, PK, indexed) · `nombre` (String(100), nullable=False) · `apellido` (String(100), nullable=False) · `email` (String(150), unique, indexed, nullable=False) · `password_hash` (String(255), nullable=False) · `activo` (Boolean, default true, nullable=False) · `rol` (String(30), default "cliente", nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=True, indexed) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `fecha_creacion` (DateTime, default UTC, nullable=False) |
| `Rol` | `roles` | `backend/app/models/role.py` | `id` (Integer, PK, indexed) · `nombre` (String(30), unique, nullable=False) · `descripcion` (String(150), nullable=True) · `activo` (Boolean, default true, nullable=False) |
| `Permiso` | `permisos` | `backend/app/models/permission.py` | `id` (Integer, PK, indexed) · `nombre` (String(100), unique, nullable=False) · `descripcion` (String(255), nullable=False) · `activo` (Boolean, default true, nullable=False) |
| `RolPermiso` | `rol_permisos` | `backend/app/models/permission.py` | `id` (Integer, PK, indexed) · `rol` (String(30), nullable=False, indexed) · `permiso_id` (Integer, FK `permisos.id`, nullable=False, ondelete CASCADE) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| GET | `/api/usuarios` | `backend/app/api/routes/users.py` | ✅ Implementado — lista usuarios de la empresa |
| POST | `/api/usuarios` | `backend/app/api/routes/users.py` | ✅ Implementado — crea usuario con rol válido |
| GET | `/api/usuarios/{usuario_id}` | `backend/app/api/routes/users.py` | ✅ Implementado |
| PUT | `/api/usuarios/{usuario_id}` | `backend/app/api/routes/users.py` | ✅ Implementado — actualiza email/rol/activo |
| DELETE | `/api/usuarios/{usuario_id}` | `backend/app/api/routes/users.py` | ✅ Implementado — elimina usuario |

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| GET | `/api/roles` | `backend/app/api/routes/roles.py` | ✅ Implementado — catálogo dinámico de roles |
| POST | `/api/roles` | `backend/app/api/routes/roles.py` | ✅ Implementado |
| PUT | `/api/roles/{rol_id}` | `backend/app/api/routes/roles.py` | ✅ Implementado |
| DELETE | `/api/roles/{rol_id}` | `backend/app/api/routes/roles.py` | ✅ Implementado — desactiva rol |

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| GET | `/api/permisos` | `backend/app/api/routes/permissions.py` | ✅ Implementado — solo administrador |
| GET | `/api/permisos/rol/{rol}` | `backend/app/api/routes/permissions.py` | ✅ Implementado |
| POST | `/api/permisos/asignar` | `backend/app/api/routes/permissions.py` | ✅ Implementado |
| DELETE | `/api/permisos/quitar/{rol}/{permiso_id}` | `backend/app/api/routes/permissions.py` | ✅ Implementado |

**Servicios / funciones:** backend en `backend/app/services/role_service.py` — `listar_roles`, `obtener_rol_por_id`, `nombres_roles_activos`, `crear_rol`, `actualizar_rol`, `eliminar_rol`. Las rutas de usuarios no usan service dedicado (lógica inline en `backend/app/api/routes/users.py`).

**Necesidades del CU | Estado**

| Necesidad | Estado |
|-----------|--------|
| Crear usuario / asignar rol / desactivar usuario | ✅ Implementado |
| Asignar / quitar permisos a rol | ✅ Implementado |

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/usuarios` | `frontend/src/app/pages/usuarios/usuarios.ts` · ruta `/usuarios` | ✅ Implementado |
| `pages/permisos` | `frontend/src/app/pages/permisos/permisos.ts` · ruta `/permisos` | ✅ Implementado |
| `pages/admin-configuracion` (pestaña `roles`) | `frontend/src/app/pages/admin-configuracion/admin-configuracion.ts` · ruta `/admin/configuracion` | ✅ Implementado |

Servicios frontend: `core/services/usuarios.service.ts`, `core/services/roles.service.ts`, `core/services/permisos.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/usuarios_page.dart` | `mobile/lib/screens/usuarios_page.dart` | ✅ Implementado |
| `screens/roles_page.dart` | `mobile/lib/screens/roles_page.dart` | ✅ Implementado |
| `screens/permisos_page.dart` | `mobile/lib/screens/permisos_page.dart` | ✅ Implementado |
| Servicio `services/usuarios_service.dart` | `mobile/lib/services/usuarios_service.dart` | ✅ Implementado |

**Flujo:** `GET /api/usuarios` → `POST`/`PUT /api/usuarios` → selector de rol con `GET /api/roles` → `GET`/`POST /api/permisos...` para permisos.

---

# CU05 — Gestionar sucursales

**RF asociado:** RF03 — Administrar ciudades y sucursales
**Actor principal:** Administrador
**Estado general:** ✅ IMPLEMENTADO

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Sucursal` | `sucursales` | `backend/app/models/branch.py` | `id` (Integer, PK, indexed) · `nombre` (String(100), unique, nullable=False) · `direccion` (String(255), nullable=False) · `ciudad` (String(100), nullable=False) · `telefono` (String(30), nullable=True) · `activo` (Boolean, default true, nullable=False) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| GET | `/api/sucursales` | `backend/app/api/routes/branches.py` | ✅ Implementado — lista sucursales por `empresa_id` (query `solo_activos`) |
| GET | `/api/sucursales/{sucursal_id}` | `backend/app/api/routes/branches.py` | ✅ Implementado |
| POST | `/api/sucursales` | `backend/app/api/routes/branches.py` | ✅ Implementado — admin; valida límite de sucursales del plan activo (RN-SaaS-01) |
| PUT | `/api/sucursales/{sucursal_id}` | `backend/app/api/routes/branches.py` | ✅ Implementado |
| DELETE | `/api/sucursales/{sucursal_id}` | `backend/app/api/routes/branches.py` | ✅ Implementado — desactiva sucursal |

**Servicios / funciones:** `backend/app/services/branch_service.py` — `listar_sucursales`, `actualizar_sucursal`, `eliminar_sucursal`; el alta de sucursal con límite de plan se valida en la ruta (`branches.py`) contra `Suscripcion` / `Plan`.

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/admin-catalogo` (pestaña `sucursales`) | `frontend/src/app/pages/admin-catalogo/admin-catalogo.ts` · ruta `/admin/catalogo` | ✅ Implementado |
| `pages/carrito` · `pages/checkout` · `pages/reservas` · `pages/punto-venta` · `pages/admin-inventario` · `pages/admin-operaciones` | selección de sucursal (`core/services/sucursales.service.ts`) | ✅ Implementado |

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/admin_catalogo_page.dart` (tab `Sucursales`) | `mobile/lib/screens/admin_catalogo_page.dart` | ✅ Implementado |
| `screens/carrito_page.dart` · `screens/mis_reservas_page.dart` · `screens/punto_venta_page.dart` · `screens/admin_inventario_page.dart` · `screens/admin_operaciones_page.dart` | mobile | ✅ Implementado |

**Servicios:** `core/services/sucursales.service.ts` (web) y `mobile/lib/services/sucursales_service.dart` (móvil).

---

# CU06 — Gestionar catálogo

**RF asociado:** RF04 — Gestionar productos de ropa
**Actor principal:** Administrador
**Estado general:** ✅ IMPLEMENTADO

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Producto` | `productos` | `backend/app/models/product.py` | `id` (Integer, PK, indexed) · `nombre` (String(150), nullable=False) · `descripcion` (Text, nullable) · `imagen_url` (String(500), nullable) · `modelo_ar_url` (String(500), nullable) · `precio` (Numeric(10,2), nullable=False) · `precio_mayorista` (Numeric(10,2), nullable) · `cantidad_mayorista` (Integer, nullable) · `categoria_id` (Integer, FK `categorias.id`, nullable=False) · `proveedor_id` (Integer, FK `proveedores.id`, nullable=True) · `temporada_id` (Integer, FK `temporadas.id`, nullable=True) · `coleccion_id` (Integer, FK `colecciones.id`, nullable=True) · `tipo_prenda_id` (Integer, FK `tipos_prenda.id`, nullable=True) · `marca_id` (Integer, FK `marcas.id`, nullable=True) · `descuento_id` (Integer, FK `descuentos.id`, nullable=True) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `activo` (Boolean, default true, nullable=False) |
| `ProductoVariante` | `producto_variantes` | `backend/app/models/product_variant.py` | `id` (Integer, PK, indexed) · `producto_id` (Integer, FK `productos.id`, nullable=False) · `talla_id` (Integer, FK `tallas.id`, nullable=False) · `color_id` (Integer, FK `colores.id`, nullable=False) · `nombre_variante` (String(120), nullable=True) · `imagen_url` (String(500), nullable=True) · `activo` (Boolean, default true, nullable=False) |

Modelos de apoyo del catálogo: `Categoria` (`categorias`), `Marca` (`marcas`), `Proveedor` (`proveedores`), `Temporada` (`temporadas`), `Coleccion` (`colecciones`), `TipoPrenda` (`tipos_prenda`), `Talla` (`tallas`), `Color` (`colores`) y `Descuento` (`descuentos`).

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| GET | `/api/productos` | `backend/app/api/routes/products.py` | ✅ Implementado — lista con filtros (`categoria_id`, `marca_id`, `tipo_prenda_id`, `coleccion_id`, `temporada_id`, `proveedor_id`, `solo_activos`) |
| GET | `/api/productos/{producto_id}` | `backend/app/api/routes/products.py` | ✅ Implementado |
| POST | `/api/productos` | `backend/app/api/routes/products.py` | ✅ Implementado — admin; asigna `empresa_id` |
| PUT | `/api/productos/{producto_id}` | `backend/app/api/routes/products.py` | ✅ Implementado |
| DELETE | `/api/productos/{producto_id}` | `backend/app/api/routes/products.py` | ✅ Implementado — soft delete (`activo=false`) |

Recursos de apoyo: `/api/categorias`, `/api/variantes`, `/api/marcas`, `/api/proveedores`, `/api/tipos-prenda`, `/api/temporadas`, `/api/colecciones`, `/api/tallas`, `/api/colores`, `/api/descuentos`.

**Servicios / funciones:** `backend/app/services/product_service.py` — `listar_productos`, `crear_producto`, `actualizar_producto`, `eliminar_producto` (maneja `descuento_id`, `precio`, `precio_mayorista`); servicios de apoyo: `category_service`, `product_variant_service`, `brand_service`, `supplier_service`, `season_service`, `collection_service`, `garment_type_service`, `size_service`, `color_service`, `discount_service`.

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/admin-catalogo` | `frontend/src/app/pages/admin-catalogo/admin-catalogo.ts` · ruta `/admin/catalogo` | ✅ Implementado |

Pestañas (`Pestana`): `categorias`, `productos`, `variantes`, `sucursales`, `proveedores`, `temporadas`, `colecciones`, `tallas`, `colores`, `tipos-prenda`, `marcas`, `descuentos`.

Servicios frontend: `core/services/productos.service.ts`, `categorias.service.ts`, `variantes.service.ts`, `marcas.service.ts`, `proveedores.service.ts`, `temporadas.service.ts`, `colecciones.service.ts`, `tipos-prenda.service.ts`, `tallas.service.ts`, `colores.service.ts`, `descuentos.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/admin_catalogo_page.dart` | `mobile/lib/screens/admin_catalogo_page.dart` | ✅ Implementado |

Pestañas (Tab): `Categorías`, `Productos`, `Variantes`, `Tallas`, `Colores`, `Tipo de Prenda`, `Marcas`, `Descuentos`, `Sucursales`, `Proveedores`, `Temporadas`, `Colecciones`.

---

# CU07 — Consultar catálogo

**RF asociado:** RF07 — Consultar catálogo web y móvil
**Actor principal:** Cliente, Administrador
**Estado general:** ✅ IMPLEMENTADO

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Producto` | `productos` | `backend/app/models/product.py` | `id` (Integer, PK, indexed) · `nombre` (String(150), nullable=False) · `descripcion` (Text, nullable) · `imagen_url` (String(500), nullable) · `modelo_ar_url` (String(500), nullable) · `precio` (Numeric(10,2), nullable=False) · `precio_mayorista` (Numeric(10,2), nullable) · `cantidad_mayorista` (Integer, nullable) · `categoria_id` (Integer, FK `categorias.id`, nullable=False) · `proveedor_id` (Integer, FK `proveedores.id`, nullable=True) · `temporada_id` (Integer, FK `temporadas.id`, nullable=True) · `coleccion_id` (Integer, FK `colecciones.id`, nullable=True) · `tipo_prenda_id` (Integer, FK `tipos_prenda.id`, nullable=True) · `marca_id` (Integer, FK `marcas.id`, nullable=True) · `descuento_id` (Integer, FK `descuentos.id`, nullable=True) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `activo` (Boolean, default true, nullable=False) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| GET | `/api/productos` | `backend/app/api/routes/products.py` | ✅ Implementado — catálogo con filtros (`categoria_id`, `marca_id`, `tipo_prenda_id`, `coleccion_id`, `temporada_id`, `proveedor_id`, `solo_activos`) |
| GET | `/api/productos/{producto_id}` | `backend/app/api/routes/products.py` | ✅ Implementado — detalle del producto |

**Servicios / funciones:** `backend/app/services/product_service.py` — `listar_productos`, `obtener_producto_por_id`, `crear_producto`, `actualizar_producto`, `eliminar_producto`.

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/catalogo` | `frontend/src/app/pages/catalogo/catalogo.ts` · ruta `/catalogo` | ✅ Implementado |
| `pages/producto-detalle` | `frontend/src/app/pages/producto-detalle/producto-detalle.ts` · ruta `/producto/:id` | ✅ Implementado |

Servicios frontend: `core/services/productos.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/catalogo_page.dart` | `mobile/lib/screens/catalogo_page.dart` | ✅ Implementado |
| `screens/producto_detalle_page.dart` | `mobile/lib/screens/producto_detalle_page.dart` | ✅ Implementado |

Servicio mobile: `mobile/lib/services/catalogo_service.dart`.

---

# CU08 — Gestionar clientes

**RF asociado:** RF01 — Registrar clientes (Gestión Multitenant y Empresas)
**Actor principal:** Administrador, Cliente
**Estado general:** ✅ IMPLEMENTADO

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Usuario` | `usuarios` | `backend/app/models/user.py` | `id` (Integer, PK, indexed) · `nombre` (String(100), nullable=False) · `apellido` (String(100), nullable=False) · `email` (String(150), unique, indexed, nullable=False) · `password_hash` (String(255), nullable=False) · `activo` (Boolean, default true, nullable=False) · `rol` (String(30), default "cliente", nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=True, indexed) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `fecha_creacion` (DateTime, default UTC, nullable=False) |
| `Pedido` | `pedidos` | `backend/app/models/order.py` | `id` (Integer, PK, indexed) · `usuario_id` (Integer, FK `usuarios.id`, nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=True) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `fecha_pedido` (DateTime, nullable=False) · `estado` (String(30), default "pendiente", nullable=False) · `total` (Numeric(10,2), default 0, nullable=False) · `detalles` (relación `DetallePedido`) |

`DetallePedido` (`detalle_pedido`): `pedido_id` (FK `pedidos.id`) · `variante_id` (FK `producto_variantes.id`) · `cantidad` (Integer) · `precio_unitario` (Numeric(10,2)).

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| POST | `/api/auth/registro` | `backend/app/api/routes/auth.py` | ✅ Implementado — registra cliente (rol `cliente`) y asigna tenant (`empresa_id`, por defecto la empresa "MenStyle") |
| GET | `/api/usuarios` | `backend/app/api/routes/users.py` | ✅ Implementado — lista clientes de la empresa |
| POST | `/api/usuarios` | `backend/app/api/routes/users.py` | ✅ Implementado — crea cliente con rol válido |
| PUT | `/api/usuarios/{usuario_id}` | `backend/app/api/routes/users.py` | ✅ Implementado — actualiza cliente |
| DELETE | `/api/usuarios/{usuario_id}` | `backend/app/api/routes/users.py` | ✅ Implementado — elimina cliente |

**Servicios / funciones:** `backend/app/services/order_service.py` — `crear_pedido_desde_carrito` y `crear_venta_presencial` (generan pedidos a nombre de un cliente existente); el registro de cliente no usa service dedicado (lógica en `backend/app/api/routes/auth.py`).

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/registro` | `frontend/src/app/pages/registro/registro.ts` · ruta `/registro` | ✅ Implementado |
| `pages/usuarios` | `frontend/src/app/pages/usuarios/usuarios.ts` · ruta `/usuarios` | ✅ Implementado |
| `pages/catalogo` · `pages/producto-detalle` · `pages/carrito` · `pages/checkout` · `pages/pedidos` | compra como cliente | ✅ Implementado |

Servicios frontend: `core/services/auth.service.ts`, `core/services/usuarios.service.ts`, `core/services/carrito.service.ts`, `core/services/pedidos.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/registro_page.dart` | `mobile/lib/screens/registro_page.dart` | ✅ Implementado |
| `screens/usuarios_page.dart` | `mobile/lib/screens/usuarios_page.dart` | ✅ Implementado |
| `screens/mis_pedidos_page.dart` | `mobile/lib/screens/mis_pedidos_page.dart` | ✅ Implementado |

Servicios mobile: `mobile/lib/services/auth_service.dart`, `mobile/lib/services/usuarios_service.dart`, `mobile/lib/services/pedidos_service.dart`.

---

# CU09 — Gestionar inventario

**RF asociado:** RF20 — Actualizar inventario automáticamente (RF20 / RF21 / RF22 — control de existencias)
**Actor principal:** Administrador, Encargado de tienda
**Estado general:** ✅ IMPLEMENTADO

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Inventario` | `inventarios` | `backend/app/models/inventory.py` | `id` (Integer, PK, indexed) · `variante_id` (Integer, FK `producto_variantes.id`, nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=False) · `cantidad` (Integer, default 0, nullable=False) · `cantidad_reservada` (Integer, default 0, nullable=False) · relación `variante` (eager load) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| GET | `/api/inventario` | `backend/app/api/routes/inventory.py` | ✅ Implementado — filtra por `sucursal_id`, `variante_id` y empresa |
| GET | `/api/inventario/detallado` | `backend/app/api/routes/inventory.py` | ✅ Implementado — paginado y enriquecido |
| GET | `/api/inventario/{inventario_id}` | `backend/app/api/routes/inventory.py` | ✅ Implementado |
| POST | `/api/inventario` | `backend/app/api/routes/inventory.py` | ✅ Implementado — admin; valida variante y sucursal de la empresa |
| PUT | `/api/inventario/{inventario_id}` | `backend/app/api/routes/inventory.py` | ✅ Implementado |
| DELETE | `/api/inventario/{inventario_id}` | `backend/app/api/routes/inventory.py` | ✅ Implementado |

**Servicios / funciones:** `backend/app/services/inventory_service.py` — `listar_inventario`, `listar_inventario_paginado`, `obtener_inventario_por_id`, `crear_inventario`, `actualizar_inventario`, `eliminar_inventario`.

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/admin-inventario` | `frontend/src/app/pages/admin-inventario/admin-inventario.ts` · ruta `/admin/inventario` | ✅ Implementado |

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/admin_inventario_page.dart` | `mobile/lib/screens/admin_inventario_page.dart` | ✅ Implementado |

Además: RF20 — decremento automático del inventario tras una venta (`backend/app/services/order_service.py`: `crear_venta_presencial`, `crear_pedido_desde_carrito`).

---

# CU10 — Gestionar ventas presenciales

**RF asociado:** RF17 — Registrar ventas presenciales (RF18 — Pagos en punto de caja)
**Actor principal:** Administrador, Encargado de caja
**Estado general:** ✅ IMPLEMENTADO

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Pedido` | `pedidos` | `backend/app/models/order.py` | `id` (Integer, PK, indexed) · `usuario_id` (Integer, FK `usuarios.id`, nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=True) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `fecha_pedido` (DateTime, nullable=False) · `estado` (String(30), default "pendiente", nullable=False) · `total` (Numeric(10,2), default 0, nullable=False) · `detalles` (relación `DetallePedido`) |
| `DetallePedido` | `detalle_pedido` | `backend/app/models/order_detail.py` | `pedido_id` (FK `pedidos.id`) · `variante_id` (FK `producto_variantes.id`) · `cantidad` (Integer) · `precio_unitario` (Numeric(10,2)) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| POST | `/api/pedidos/venta-presencial` | `backend/app/api/routes/orders.py` | ✅ Implementado — admin; valida items contra la empresa y genera el pedido |
| GET | `/api/pedidos/admin/todas` | `backend/app/api/routes/orders.py` | ✅ Implementado — admin |
| GET | `/api/pedidos` | `backend/app/api/routes/orders.py` | ✅ Implementado — pedidos del usuario autenticado |
| GET | `/api/pedidos/{pedido_id}` | `backend/app/api/routes/orders.py` | ✅ Implementado |
| PUT | `/api/pedidos/{pedido_id}/estado` | `backend/app/api/routes/orders.py` | ✅ Implementado — admin |

**Servicios / funciones:** `backend/app/services/order_service.py` — `crear_venta_presencial`, `listar_todos_los_pedidos`, `cambiar_estado_pedido_admin`, `crear_pedido_desde_carrito`.

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/punto-venta` | `frontend/src/app/pages/punto-venta/punto-venta.ts` · ruta `/admin/punto-venta` | ✅ Implementado |
| `pages/admin-operaciones` | `frontend/src/app/pages/admin-operaciones/admin-operaciones.ts` · ruta `/admin/operaciones` | ✅ Implementado |

Servicios frontend: `core/services/pedidos.service.ts`, `core/services/pagos.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/punto_venta_page.dart` | `mobile/lib/screens/punto_venta_page.dart` | ✅ Implementado |

Servicio mobile: `mobile/lib/services/pedidos_service.dart`.

---

# CU11 — Gestionar reservas

**RF asociado:** RF10 — Registrar y gestionar reservas (RF09, RF11, RF12)
**Actor principal:** Cliente, Encargado de tienda
**Estado general:** ✅ IMPLEMENTADO

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Reserva` | `reservas` | `backend/app/models/reservation.py` | `id` (Integer, PK, indexed) · `usuario_id` (Integer, FK `usuarios.id`, nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=False) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `fecha_reserva` (DateTime, nullable=False) · `estado` (String(30), default "pendiente", nullable=False) · `observaciones` (String(255), nullable=True) · `detalles` (relación `DetalleReserva`) |
| `DetalleReserva` | `detalle_reservas` | `backend/app/models/reservation_detail.py` | `reserva_id` (FK `reservas.id`) · `variante_id` (FK `producto_variantes.id`) · `cantidad` (Integer) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| GET | `/api/reservas` | `backend/app/api/routes/reservations.py` | ✅ Implementado — reservas del usuario autenticado |
| GET | `/api/reservas/admin/todas` | `backend/app/api/routes/reservations.py` | ✅ Implementado — admin |
| GET | `/api/reservas/{reserva_id}` | `backend/app/api/routes/reservations.py` | ✅ Implementado |
| POST | `/api/reservas` | `backend/app/api/routes/reservations.py` | ✅ Implementado — crea reserva (verifica stock) |
| PUT | `/api/reservas/{reserva_id}/estado` | `backend/app/api/routes/reservations.py` | ✅ Implementado |

**Servicios / funciones:** `backend/app/services/reservation_service.py` — `listar_reservas_usuario`, `listar_todas_las_reservas`, creación y cambio de estado de reservas.

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/reservas` | `frontend/src/app/pages/reservas/reservas.ts` · ruta `/reservas` | ✅ Implementado |

Servicios frontend: `core/services/reservas.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/mis_reservas_page.dart` | `mobile/lib/screens/mis_reservas_page.dart` | ✅ Implementado |
| `screens/admin_operaciones_page.dart` | `mobile/lib/screens/admin_operaciones_page.dart` | ✅ Implementado |

Servicio mobile: `mobile/lib/services/reservas_service.dart`.

---

# CU12 — Gestionar cambio de prendas

**RF asociado:** RF17 — Registrar ventas presenciales (relacionado con cambios/devoluciones sobre el pedido)
**Actor principal:** Cliente, Administrador
**Estado general:** ⚠️ Parcial

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Devolucion` | `devoluciones` | `backend/app/models/return_model.py` | `id` (Integer, PK, indexed) · `pedido_id` (Integer, FK `pedidos.id`, nullable=False) · `variante_id` (Integer, FK `producto_variantes.id`, nullable=False) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `cantidad` (Integer, nullable=False) · `motivo` (String(255), nullable=False) · `estado` (String(30), default "pendiente", nullable=False) · `fecha_devolucion` (DateTime, nullable=False) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| GET | `/api/devoluciones` | `backend/app/api/routes/returns.py` | ✅ Implementado — devoluciones del usuario autenticado |
| GET | `/api/devoluciones/{devolucion_id}` | `backend/app/api/routes/returns.py` | ✅ Implementado |
| POST | `/api/devoluciones` | `backend/app/api/routes/returns.py` | ✅ Implementado — solicita devolución (valida empresa del pedido) |
| PUT | `/api/devoluciones/{devolucion_id}/estado` | `backend/app/api/routes/returns.py` | ✅ Implementado — admin |

**Servicios / funciones:** `backend/app/services/return_service.py` — `listar_devoluciones_usuario`, `obtener_devolucion_por_id`, `solicitar_devolucion`, `cambiar_estado_devolucion_admin`.

## 3. Pantallas del frontend

- **Estado:** ❌ PENDIENTE

No existe pantalla de gestión de cambios/devoluciones en el frontend. Solo se referencia el flujo en `frontend/src/app/pages/producto-detalle` (textos de "Cambios y devoluciones" / "30 días para cambios por talla o color").

## 4. Pantallas del mobile

- **Estado:** ❌ PENDIENTE

No existe pantalla de cambios/devoluciones en el mobile.

---

# CU13 — Registrarse como cliente y comprar

**RF asociado:** RF01 — Registrar clientes (RF14 — Agregar productos al carrito / RF15, RF16 — Comprar desde web y app móvil)
**Actor principal:** Cliente
**Estado general:** ✅ IMPLEMENTADO

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Usuario` | `usuarios` | `backend/app/models/user.py` | `id` (Integer, PK, indexed) · `nombre` (String(100), nullable=False) · `apellido` (String(100), nullable=False) · `email` (String(150), unique, indexed, nullable=False) · `password_hash` (String(255), nullable=False) · `activo` (Boolean, default true, nullable=False) · `rol` (String(30), default "cliente", nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=True, indexed) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `fecha_creacion` (DateTime, default UTC, nullable=False) |
| `Carrito` | `carritos` | `backend/app/models/cart.py` | `id` (Integer, PK, indexed) · `usuario_id` (Integer, FK `usuarios.id`, nullable=False) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `detalles` (relación `DetalleCarrito`) |
| `DetalleCarrito` | `detalles_carrito` | `backend/app/models/cart_detail.py` | `id` (Integer, PK, indexed) · `carrito_id` (Integer, FK `carritos.id`, nullable=False) · `variante_id` (Integer, FK `producto_variantes.id`, nullable=False) · `cantidad` (Integer, default 1, nullable=False) |
| `Pedido` | `pedidos` | `backend/app/models/order.py` | `id` (Integer, PK, indexed) · `usuario_id` (Integer, FK `usuarios.id`, nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=True) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `fecha_pedido` (DateTime, nullable=False) · `estado` (String(30), default "pendiente", nullable=False) · `total` (Numeric(10,2), default 0, nullable=False) · `detalles` (relación `DetallePedido`) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| POST | `/api/auth/registro` | `backend/app/api/routes/auth.py` | ✅ Implementado — registro de cliente con rol `cliente` y tenant |
| GET | `/api/carrito` | `backend/app/api/routes/cart.py` | ✅ Implementado — obtiene carrito del usuario |
| POST | `/api/carrito/items` | `backend/app/api/routes/cart.py` | ✅ Implementado — agrega variante al carrito (valida empresa) |
| PUT | `/api/carrito/items/{detalle_id}` | `backend/app/api/routes/cart.py` | ✅ Implementado — actualiza cantidad |
| DELETE | `/api/carrito/items/{detalle_id}` | `backend/app/api/routes/cart.py` | ✅ Implementado — elimina item |
| DELETE | `/api/carrito` | `backend/app/api/routes/cart.py` | ✅ Implementado — vacía carrito |
| POST | `/api/pedidos` | `backend/app/api/routes/orders.py` | ✅ Implementado — `crear_pedido_desde_carrito` |

**Servicios / funciones:** `backend/app/services/cart_service.py` — `obtener_o_crear_carrito`, `obtener_carrito`, `agregar_producto_al_carrito`, `actualizar_detalle_carrito`, `eliminar_detalle_carrito`, `vaciar_carrito`; `backend/app/services/order_service.py` — `crear_pedido_desde_carrito`.

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/registro` | `frontend/src/app/pages/registro/registro.ts` · ruta `/registro` | ✅ Implementado |
| `pages/catalogo` | `frontend/src/app/pages/catalogo/catalogo.ts` · ruta `/catalogo` | ✅ Implementado |
| `pages/producto-detalle` | `frontend/src/app/pages/producto-detalle/producto-detalle.ts` · ruta `/producto/:id` | ✅ Implementado |
| `pages/carrito` | `frontend/src/app/pages/carrito/carrito.ts` · ruta `/carrito` | ✅ Implementado |
| `pages/checkout` | `frontend/src/app/pages/checkout/checkout.ts` · ruta `/checkout/:pedidoId` | ✅ Implementado |
| `pages/pedidos` | `frontend/src/app/pages/pedidos/pedidos.ts` · ruta `/pedidos` | ✅ Implementado |

Servicios frontend: `core/services/auth.service.ts`, `core/services/carrito.service.ts`, `core/services/pedidos.service.ts`, `core/services/pagos.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/registro_page.dart` | `mobile/lib/screens/registro_page.dart` | ✅ Implementado |
| `screens/catalogo_page.dart` | `mobile/lib/screens/catalogo_page.dart` | ✅ Implementado |
| `screens/producto_detalle_page.dart` | `mobile/lib/screens/producto_detalle_page.dart` | ✅ Implementado |
| `screens/carrito_page.dart` | `mobile/lib/screens/carrito_page.dart` | ✅ Implementado |
| `screens/mis_pedidos_page.dart` | `mobile/lib/screens/mis_pedidos_page.dart` | ✅ Implementado |

Servicios mobile: `mobile/lib/services/auth_service.dart`, `mobile/lib/services/carrito_service.dart`, `mobile/lib/services/pedidos_service.dart`.

---

# CU14 — Usar probador virtual AR

**RF asociado:** RF13 — Vestidor virtual (RA)
**Actor principal:** Cliente
**Estado general:** ✅ IMPLEMENTADO

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Producto` | `productos` | `backend/app/models/product.py` | `id` (Integer, PK, indexed) · `nombre` (String(150), nullable=False) · `imagen_url` (String(500), nullable) · `modelo_ar_url` (String(500), nullable) · `precio` (Numeric(10,2), nullable=False) · `categoria_id` (Integer, FK `categorias.id`, nullable=False) · `activo` (Boolean, default true, nullable=False) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| GET | `/api/productos/{producto_id}` | `backend/app/api/routes/products.py` | ✅ Implementado — detalle del producto con `modelo_ar_url` |
| POST | `/api/ia/recomendar` | `backend/app/api/routes/ia.py` | ✅ Implementado — recomendaciones de IA |
| POST | `/api/ia/chat` | `backend/app/api/routes/ia.py` | ✅ Implementado — asistente virtual |
| GET | `/api/ia/tendencias` | `backend/app/api/routes/ia.py` | ✅ Implementado — tendencias |

**Servicios / funciones:** `backend/app/services/ia_service.py` — `recomendar_para_usuario`, `responder_consulta`, `productos_tendencia` (lógica de recomendaciones/Asistente Virtual).

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/vestidor` | `frontend/src/app/pages/vestidor/vestidor.ts` · ruta `/vestidor` | ✅ Implementado |

Servicios frontend: `core/services/ia.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/vestidor_virtual_page.dart` | `mobile/lib/screens/vestidor_virtual_page.dart` | ✅ Implementado |
| `screens/chat_page.dart` | `mobile/lib/screens/chat_page.dart` | ✅ Implementado |

Servicio mobile: `mobile/lib/services/chat_service.dart`.

---

# CU26 — Procesar pago

**RF asociado:** RF18 — Pagos en punto de caja / RF19 — Integrar pasarela de pago
**Actor principal:** Cliente, Administrador (punto de caja)
**Estado general:** ✅ IMPLEMENTADO

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Pago` | `pagos` | `backend/app/models/payment.py` | `id` (Integer, PK, indexed) · `pedido_id` (Integer, FK `pedidos.id`, nullable=False) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `metodo` (String(30), nullable=False) · `monto` (Numeric(10,2), nullable=False) · `estado` (String(30), default "pendiente", nullable=False) · `referencia` (String(150), nullable=True) · `fecha_pago` (DateTime, nullable=True) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| POST | `/api/pagos` | `backend/app/api/routes/payments.py` | ✅ Implementado — registra pago de un pedido |
| GET | `/api/pagos/pedido/{pedido_id}` | `backend/app/api/routes/payments.py` | ✅ Implementado |
| GET | `/api/pagos/stripe/config` | `backend/app/api/routes/payments.py` | ✅ Implementado |
| POST | `/api/pagos/stripe/intent` | `backend/app/api/routes/payments.py` | ✅ Implementado — crea PaymentIntent de Stripe |
| POST | `/api/pagos/stripe/confirm` | `backend/app/api/routes/payments.py` | ✅ Implementado — confirma pago |
| POST | `/api/pagos/stripe/webhook` | `backend/app/api/routes/payments.py` | ✅ Implementado — recibe eventos de Stripe |

**Servicios / funciones:** `backend/app/services/payment_service.py` — `registrar_pago`, `listar_pagos_pedido`; `backend/app/services/stripe_service.py` — `obtener_config_publica`, `crear_payment_intent`, `confirmar_pago`, `procesar_webhook`.

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/checkout` | `frontend/src/app/pages/checkout/checkout.ts` · ruta `/checkout/:pedidoId` | ✅ Implementado |
| `pages/punto-venta` | `frontend/src/app/pages/punto-venta/punto-venta.ts` · ruta `/admin/punto-venta` | ✅ Implementado |
| `pages/pedidos` | `frontend/src/app/pages/pedidos/pedidos.ts` · ruta `/pedidos` | ✅ Implementado |

Servicios frontend: `core/services/pagos.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/punto_venta_page.dart` | `mobile/lib/screens/punto_venta_page.dart` | ✅ Implementado |
| `screens/pago_qr_page.dart` | `mobile/lib/screens/pago_qr_page.dart` | ✅ Implementado |

Servicios mobile: `mobile/lib/services/stripe_service.dart`, `mobile/lib/services/pedidos_service.dart`.

---

# CU27 — Gestionar listas de precios

**RF asociado:** RF04 — Gestionar productos de ropa (listas de precios / descuentos)
**Actor principal:** Administrador
**Estado general:** ✅ IMPLEMENTADO

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Descuento` | `descuentos` | `backend/app/models/discount.py` | `id` (Integer, PK, indexed) · `nombre` (String(100), nullable=False) · `porcentaje` (Numeric(5,2), nullable=False) · `fecha_inicio` (Date, nullable=True) · `fecha_fin` (Date, nullable=True) · `activo` (Boolean, default true, nullable=False) |
| `Producto` | `productos` | `backend/app/models/product.py` | `id` (Integer, PK, indexed) · `nombre` (String(150), nullable=False) · `precio` (Numeric(10,2), nullable=False) · `precio_mayorista` (Numeric(10,2), nullable) · `cantidad_mayorista` (Integer, nullable) · `descuento_id` (Integer, FK `descuentos.id`, nullable=True) · `categoria_id` (Integer, FK `categorias.id`, nullable=False) · `marca_id` (Integer, FK `marcas.id`, nullable=True) · `temporada_id` (Integer, FK `temporadas.id`, nullable=True) · `coleccion_id` (Integer, FK `colecciones.id`, nullable=True) · `tipo_prenda_id` (Integer, FK `tipos_prenda.id`, nullable=True) · `proveedor_id` (Integer, FK `proveedores.id`, nullable=True) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `activo` (Boolean, default true, nullable=False) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| GET | `/api/descuentos` | `backend/app/api/routes/discounts.py` | ✅ Implementado — listas de precios / promociones |
| POST | `/api/descuentos` | `backend/app/api/routes/discounts.py` | ✅ Implementado |
| PUT | `/api/descuentos/{descuento_id}` | `backend/app/api/routes/discounts.py` | ✅ Implementado |
| DELETE | `/api/descuentos/{descuento_id}` | `backend/app/api/routes/discounts.py` | ✅ Implementado — desactiva |

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| PUT | `/api/productos/{producto_id}` | `backend/app/api/routes/products.py` | ✅ Implementado — actualiza `precio`, `precio_mayorista` y `descuento_id` |

**Servicios / funciones:** `backend/app/services/discount_service.py` — `listar_descuentos`, `obtener_descuento_por_id`, `crear_descuento`, `actualizar_descuento`, `eliminar_descuento`; `backend/app/services/product_service.py` — `listar_productos`, `crear_producto`, `actualizar_producto`, `eliminar_producto` (aplica descuento/precio).

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/admin-catalogo` (pestaña `descuentos` y edición de producto con precio/descuento) | `frontend/src/app/pages/admin-catalogo/admin-catalogo.ts` · ruta `/admin/catalogo` | ✅ Implementado |

Servicios frontend: `core/services/descuentos.service.ts`, `core/services/productos.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/admin_catalogo_page.dart` (tab `Descuentos`) | `mobile/lib/screens/admin_catalogo_page.dart` | ✅ Implementado |

Servicio mobile: `mobile/lib/services/discounts_service.dart`.

---
