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

# CU15 — Administrar inventario

**RF asociado:** RF20, RF21, RF22 — Actualizar automáticamente el inventario tras una venta / Controlar las existencias por sucursal / Registrar movimientos de inventario (según `docs/04_captura_requisitos/requisitos.md` y `docs/07_implementacion/trazabilidad.md`)
**Actor principal:** Administrador, Encargado de tienda (según `docs/04_captura_requisitos/casos_uso_general.puml`)
**Estado general:** ⚠️ PARCIAL

> Nota de trazabilidad: la implementación de inventario en el código también está etiquetada como CU09 (`backend/app/api/routes/inventory.py`, `frontend/src/app/pages/admin-inventario`, `mobile/lib/screens/admin_inventario_page.dart`) y ya se documenta en CU09 de este mismo archivo. Aquí se documenta la vista PUDS CU15 solicitada.

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Inventario` | `inventarios` | `backend/app/models/inventory.py` | `id` (Integer, PK, indexed) · `variante_id` (Integer, FK `producto_variantes.id`, nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=False) · `cantidad` (Integer, default 0, nullable=False) · `cantidad_reservada` (Integer, default 0, nullable=False) · relación `variante` (relationship `ProductoVariante`, lazy `joined`) |
| `ProductoVariante` | `producto_variantes` | `backend/app/models/product_variant.py` | `id` (Integer, PK, indexed) · `producto_id` (Integer, FK `productos.id`, nullable=False) · `talla_id` (Integer, FK `tallas.id`, nullable=False) · `color_id` (Integer, FK `colores.id`, nullable=False) · `nombre_variante` (String(120), nullable=True) · `imagen_url` (String(500), nullable=True) · `activo` (Boolean, default true, nullable=False) |
| `Sucursal` | `sucursales` | `backend/app/models/branch.py` | `id` (Integer, PK, indexed) · `nombre` (String(100), unique, nullable=False) · `direccion` (String(255), nullable=False) · `ciudad` (String(100), nullable=False) · `telefono` (String(30), nullable=True) · `activo` (Boolean, default true, nullable=False) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| GET | `/api/inventario` | `backend/app/api/routes/inventory.py` | ✅ Implementado — lista stock filtrable por `sucursal_id` y `variante_id`, restringido a sucursales de la empresa (RF21, CU15/CU09) |
| GET | `/api/inventario/detallado` | `backend/app/api/routes/inventory.py` | ✅ Implementado — consulta paginada y enriquecida (`producto_nombre`, `producto_imagen_url`, `variante_talla`, `variante_color`) para panel admin |
| GET | `/api/inventario/{inventario_id}` | `backend/app/api/routes/inventory.py` | ✅ Implementado — obtiene registro con validación de empresa |
| POST | `/api/inventario` | `backend/app/api/routes/inventory.py` | ✅ Implementado — crea registro (solo administrador); valida sucursal y variante de la empresa |
| PUT | `/api/inventario/{inventario_id}` | `backend/app/api/routes/inventory.py` | ✅ Implementado — actualiza cantidades (solo administrador) |
| DELETE | `/api/inventario/{inventario_id}` | `backend/app/api/routes/inventory.py` | ✅ Implementado — elimina registro (solo administrador) |

**Servicios / funciones:** `backend/app/services/inventory_service.py` — `listar_inventario`, `listar_inventario_paginado`, `obtener_inventario_por_id`, `crear_inventario`, `actualizar_inventario`, `eliminar_inventario` (incluye serialización enriquecida con eager loading de variante/producto/talla/color). RF20 (actualización automática tras venta/reserva) se ejecuta en `backend/app/services/order_service.py` (`crear_pedido_desde_carrito`, `crear_venta_presencial`, cancelaciones/reposición) y `backend/app/services/reservation_service.py` (reserva/cancelación/completado ajusta `cantidad` y `cantidad_reservada`).

**Necesidades del CU | Estado**

| Necesidad | Estado |
|-----------|--------|
| Consultar y controlar existencias por sucursal/variante (RF21) | ✅ Implementado |
| Crear/actualizar/eliminar registros de inventario (admin) | ✅ Implementado |
| Actualizar inventario automáticamente tras ventas/pedidos/reservas (RF20) | ✅ Implementado — lógica en servicios de pedidos y reservas |
| Registrar movimientos de inventario (RF22) como historial/auditoría | ❌ NO IMPLEMENTADO — no existe modelo/tabla/ruta de movimientos de inventario en `backend/app/models`, `backend/app/api/routes` ni `backend/app/services` |

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/admin-inventario` | `frontend/src/app/pages/admin-inventario/admin-inventario.ts` · ruta `/admin/inventario` | ✅ Implementado |

Servicios frontend: `frontend/src/app/core/services/inventario.service.ts`, `frontend/src/app/core/services/sucursales.service.ts`, `frontend/src/app/core/services/variantes.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/admin_inventario_page.dart` | `mobile/lib/screens/admin_inventario_page.dart` | ✅ Implementado |
| Servicio `services/inventario_service.dart` | `mobile/lib/services/inventario_service.dart` | ✅ Implementado |

**Flujo:** `GET /api/sucursales` → selección de sucursal → `GET /api/inventario` o `GET /api/inventario/detallado` → (admin) `POST`/`PUT`/`DELETE /api/inventario...`; ventas/pedidos/reservas ajustan stock vía servicios backend.

---

# CU21 — Gestionar pedido

**RF asociado:** RF15, RF16 — Comprar desde web / Comprar desde app móvil (según `docs/04_captura_requisitos/requisitos.md` y `docs/07_implementacion/trazabilidad.md`)
**Actor principal:** Cliente (gestión de estado administrativo: Administrador, según rutas `/api/pedidos/admin/*` y `PUT /api/pedidos/{id}/estado`)
**Estado general:** ✅ IMPLEMENTADO

> Nota de trazabilidad: la compra/pedido en el código también está etiquetada como CU13 (`backend/app/api/routes/orders.py`, checkout/pedidos/carrito en frontend y mobile) y se documenta en CU13. CU21 documenta la vista PUDS del pedido (web/móvil).

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Pedido` | `pedidos` | `backend/app/models/order.py` | `id` (Integer, PK, indexed) · `usuario_id` (Integer, FK `usuarios.id`, nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=True) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `uuid_offline` (String(64), nullable=True, indexed) · `fecha_pedido` (DateTime, default `datetime.utcnow`, nullable=False) · `estado` (String(50), default `"pendiente"`, nullable=False) · `total` (Numeric(10,2), default 0, nullable=False) · relación `detalles` (`DetallePedido`, backref `pedido`, cascade `all, delete-orphan`) |
| `DetallePedido` | `detalles_pedido` | `backend/app/models/order_detail.py` | `id` (Integer, PK, indexed) · `pedido_id` (Integer, FK `pedidos.id`, nullable=False) · `variante_id` (Integer, FK `producto_variantes.id`, nullable=False) · `cantidad` (Integer, nullable=False) · `precio_unitario` (Numeric(10,2), nullable=False) · `subtotal` (Numeric(10,2), nullable=False) |
| `Inventario` | `inventarios` | `backend/app/models/inventory.py` | `id` (Integer, PK, indexed) · `variante_id` (Integer, FK `producto_variantes.id`, nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=False) · `cantidad` (Integer, default 0, nullable=False) · `cantidad_reservada` (Integer, default 0, nullable=False) · relación `variante` (lazy `joined`) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| POST | `/api/pedidos` | `backend/app/api/routes/orders.py` | ✅ Implementado — crea pedido desde carrito (`crear_pedido_desde_carrito`), usuario autenticado |
| GET | `/api/pedidos` | `backend/app/api/routes/orders.py` | ✅ Implementado — lista pedidos del usuario (`estado` opcional) |
| GET | `/api/pedidos/me` | `backend/app/api/routes/orders.py` | ✅ Implementado — alias historial (CU33/RF15/RF16) |
| GET | `/api/pedidos/{pedido_id}` | `backend/app/api/routes/orders.py` | ✅ Implementado — obtiene pedido del usuario |
| PUT | `/api/pedidos/{pedido_id}/cancelar` | `backend/app/api/routes/orders.py` | ✅ Implementado — cancela pedido del cliente (reposición de stock según sucursal) |
| POST | `/api/pedidos/venta-presencial` | `backend/app/api/routes/orders.py` | ✅ Implementado — venta en punto de caja (admin, RF17/RF18) |
| GET | `/api/pedidos/admin/todos` | `backend/app/api/routes/orders.py` | ✅ Implementado — lista pedidos de la empresa (admin) |
| PUT | `/api/pedidos/{pedido_id}/estado` | `backend/app/api/routes/orders.py` | ✅ Implementado — cambia estado del pedido (admin) |

**Servicios / funciones:** `backend/app/services/order_service.py` — `listar_pedidos_usuario`, `listar_todos_los_pedidos`, `obtener_pedido_por_id`, `crear_pedido_desde_carrito` (valida sucursal, stock por variante/sucursal, descuenta inventario, vacía carrito, crea notificación), `cancelar_pedido_cliente`, `cambiar_estado_pedido_admin`, `crear_venta_presencial`.

**Necesidades del CU | Estado**

| Necesidad | Estado |
|-----------|--------|
| Crear pedido desde compra web/móvil (RF15, RF16) | ✅ Implementado — `POST /api/pedidos` desde carrito |
| Consultar historial/detalle de pedidos del cliente | ✅ Implementado — `GET /api/pedidos`, `/me`, `/{id}` |
| Cancelar pedido y reponer inventario | ✅ Implementado — `PUT /api/pedidos/{id}/cancelar` |
| Gestionar estados del pedido (admin) | ✅ Implementado — `PUT /api/pedidos/{id}/estado` |

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/checkout` | `frontend/src/app/pages/checkout/checkout.ts` · ruta `/checkout/:pedidoId` | ✅ Implementado |
| `pages/pedidos` | `frontend/src/app/pages/pedidos/pedidos.ts` · ruta `/pedidos` | ✅ Implementado |
| `pages/admin-operaciones` | `frontend/src/app/pages/admin-operaciones/admin-operaciones.ts` · ruta `/admin/operaciones` | ✅ Implementado — gestión operativa/admin |
| `pages/punto-venta` | `frontend/src/app/pages/punto-venta/punto-venta.ts` · ruta `/admin/punto-venta` | ✅ Implementado — venta presencial (relacionada) |

Servicios frontend: `frontend/src/app/core/services/pedidos.service.ts`, `frontend/src/app/core/services/carrito.service.ts`, `frontend/src/app/core/services/pagos.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/mis_pedidos_page.dart` | `mobile/lib/screens/mis_pedidos_page.dart` | ✅ Implementado |
| `screens/carrito_page.dart` | `mobile/lib/screens/carrito_page.dart` | ✅ Implementado — genera pedido/flujo de compra |
| `screens/punto_venta_page.dart` | `mobile/lib/screens/punto_venta_page.dart` | ✅ Implementado — venta presencial (relacionada) |
| Servicio `services/pedidos_service.dart` | `mobile/lib/services/pedidos_service.dart` | ✅ Implementado |

**Flujo:** carrito con items → `POST /api/pedidos` (sucursal seleccionada) → pedido `pendiente`/flujo de pago → `GET /api/pedidos`/`/me` para consulta; admin: `GET /api/pedidos/admin/todos` → `PUT /api/pedidos/{id}/estado`.

---

# CU22 — Administrar carrito de compra

**RF asociado:** RF14 — Agregar productos al carrito (según `docs/04_captura_requisitos/requisitos.md` y `docs/07_implementacion/trazabilidad.md`)
**Actor principal:** Cliente (según `docs/04_captura_requisitos/casos_uso_general.puml`)
**Estado general:** ✅ IMPLEMENTADO

> Nota de trazabilidad: el carrito en el código está integrado al flujo de compra CU13 (`backend/app/api/routes/cart.py`) y se documenta en CU13. CU22 documenta la vista PUDS específica del carrito.

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Carrito` | `carritos` | `backend/app/models/cart.py` | `id` (Integer, PK, indexed) · `usuario_id` (Integer, FK `usuarios.id`, nullable=False) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · relación `detalles` (`DetalleCarrito`, backref `carrito`, cascade `all, delete-orphan`) |
| `DetalleCarrito` | `detalles_carrito` | `backend/app/models/cart_detail.py` | `id` (Integer, PK, indexed) · `carrito_id` (Integer, FK `carritos.id`, nullable=False) · `variante_id` (Integer, FK `producto_variantes.id`, nullable=False) · `cantidad` (Integer, default 1, nullable=False) |
| `Inventario` | `inventarios` | `backend/app/models/inventory.py` | `id` (Integer, PK, indexed) · `variante_id` (Integer, FK `producto_variantes.id`, nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=False) · `cantidad` (Integer, default 0, nullable=False) · `cantidad_reservada` (Integer, default 0, nullable=False) · relación `variante` (lazy `joined`) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| GET | `/api/carrito` | `backend/app/api/routes/cart.py` | ✅ Implementado — obtiene (o crea) carrito del usuario autenticado |
| POST | `/api/carrito/items` | `backend/app/api/routes/cart.py` | ✅ Implementado — agrega variante al carrito; valida variante/producto y pertenencia a empresa |
| PUT | `/api/carrito/items/{detalle_id}` | `backend/app/api/routes/cart.py` | ✅ Implementado — actualiza cantidad del ítem |
| DELETE | `/api/carrito/items/{detalle_id}` | `backend/app/api/routes/cart.py` | ✅ Implementado — elimina ítem del carrito |
| DELETE | `/api/carrito` | `backend/app/api/routes/cart.py` | ✅ Implementado — vacía carrito |

**Servicios / funciones:** `backend/app/services/cart_service.py` — `calcular_stock_disponible` (suma stock disponible en sucursales activas), `obtener_o_crear_carrito`, `obtener_carrito`, `agregar_producto_al_carrito` (valida variante activa y stock), `actualizar_detalle_carrito`, `eliminar_detalle_carrito`, `vaciar_carrito`.

**Necesidades del CU | Estado**

| Necesidad | Estado |
|-----------|--------|
| Agregar producto/variante al carrito (RF14) | ✅ Implementado — `POST /api/carrito/items` |
| Consultar contenido del carrito | ✅ Implementado — `GET /api/carrito` |
| Modificar cantidad / eliminar ítems / vaciar carrito | ✅ Implementado — `PUT`/`DELETE /api/carrito/items/{id}`, `DELETE /api/carrito` |
| Validar disponibilidad al agregar/actualizar | ✅ Implementado — cálculo de stock disponible en `cart_service` |

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/carrito` | `frontend/src/app/pages/carrito/carrito.ts` · ruta `/carrito` | ✅ Implementado |
| `pages/catalogo` | `frontend/src/app/pages/catalogo/catalogo.ts` · ruta `/catalogo` | ✅ Implementado — origen de navegación a producto |
| `pages/producto-detalle` | `frontend/src/app/pages/producto-detalle/producto-detalle.ts` · ruta `/producto/:id` | ✅ Implementado — agrega variante al carrito |

Servicios frontend: `frontend/src/app/core/services/carrito.service.ts`, `frontend/src/app/core/services/productos.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/carrito_page.dart` | `mobile/lib/screens/carrito_page.dart` | ✅ Implementado |
| `screens/producto_detalle_page.dart` | `mobile/lib/screens/producto_detalle_page.dart` | ✅ Implementado — agrega al carrito |
| Servicio `services/carrito_service.dart` | `mobile/lib/services/carrito_service.dart` | ✅ Implementado |

**Flujo:** selección de variante en catálogo/detalle → `POST /api/carrito/items` → `GET /api/carrito` → `PUT`/`DELETE /api/carrito/items/{id}` o `DELETE /api/carrito` → checkout/pedido.

---

# CU23 — Realizar probador virtual

**RF asociado:** RF13 — Vestidor virtual (RA) (según `docs/04_captura_requisitos/requisitos.md` y `docs/07_implementacion/trazabilidad.md`)
**Actor principal:** Cliente (según `docs/04_captura_requisitos/casos_uso_general.puml`)
**Estado general:** ✅ IMPLEMENTADO

> Nota de trazabilidad: la funcionalidad ya está documentada como CU14 “Usar probador virtual AR” en este archivo (misma base técnica: `pages/vestidor`, `vestidor_virtual_page.dart`, `modelo_ar_url` e IA). En `backend/app/api/routes/ia.py` existen comentarios internos de “Segundo Parcial” que etiquetan `/api/ia/consultar` como CU23 y `/api/ia/predicciones` como CU24; esos endpoints corresponden a reportes generativos/ML, no al probador virtual PUDS CU23.

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Producto` | `productos` | `backend/app/models/product.py` | `id` (Integer, PK, indexed) · `nombre` (String(150), nullable=False) · `descripcion` (Text, nullable) · `imagen_url` (String(500), nullable) · `modelo_ar_url` (String(500), nullable) · `precio` (Numeric(10,2), nullable=False) · `precio_mayorista` (Numeric(10,2), nullable) · `cantidad_mayorista` (Integer, nullable) · `categoria_id` (Integer, FK `categorias.id`, nullable=False) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `activo` (Boolean, default true, nullable=False) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| GET | `/api/productos/{producto_id}` | `backend/app/api/routes/products.py` | ✅ Implementado — obtiene detalle del producto, incluyendo `modelo_ar_url` usado por el probador/AR |
| POST | `/api/ia/recomendar` | `backend/app/api/routes/ia.py` | ✅ Implementado — recomendaciones (CU31/RF25, soporte IA asociado) |
| POST | `/api/ia/chat` | `backend/app/api/routes/ia.py` | ✅ Implementado — asistente virtual (CU32/RF25, público) |
| GET | `/api/ia/tendencias` | `backend/app/api/routes/ia.py` | ✅ Implementado — tendencias (CU30/RF24) |

**Servicios / funciones:** `backend/app/services/ia_service.py` — `recomendar_para_usuario`, `responder_consulta`, `productos_tendencia` (y funciones adicionales de IA en el mismo servicio, p. ej. consultas/predicciones, no son el núcleo del CU23 vestidor). La experiencia AR/vestidor se apoya principalmente en datos de producto (`modelo_ar_url`/imagen) y en la UI cliente.

**Necesidades del CU | Estado**

| Necesidad | Estado |
|-----------|--------|
| Probar/prendar virtualmente productos (RF13) | ✅ Implementado — pantallas de vestidor en web y móvil |
| Obtener datos/modelo visual del producto | ✅ Implementado — `GET /api/productos/{id}` (`modelo_ar_url`, imagen) |
| Soporte de recomendaciones/asistente IA (relacionado) | ✅ Implementado — endpoints `/api/ia/*` |

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/vestidor` | `frontend/src/app/pages/vestidor/vestidor.ts` · ruta `/vestidor` | ✅ Implementado |

Servicios frontend: `frontend/src/app/core/services/ia.service.ts`, `frontend/src/app/core/services/productos.service.ts` (datos de producto/AR según flujo de vestidor).

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/vestidor_virtual_page.dart` | `mobile/lib/screens/vestidor_virtual_page.dart` | ✅ Implementado |
| `screens/chat_page.dart` | `mobile/lib/screens/chat_page.dart` | ✅ Implementado — asistente IA relacionado |
| Servicio `services/chat_service.dart` | `mobile/lib/services/chat_service.dart` | ✅ Implementado |

**Flujo:** consulta de producto/recomendaciones (`GET /api/productos/{id}`, `/api/ia/*`) → apertura de vestidor web (`/vestidor`) o móvil (`vestidor_virtual_page.dart`) con recursos visuales del producto.

---

# CU24 — Gestionar reservas

**RF asociado:** RF09, RF10, RF11, RF12 — Seleccionar múltiples prendas / Registrar y gestionar reservas / Notificar reservas a sucursal / Consultar estado de reserva (según `docs/04_captura_requisitos/requisitos.md`, `docs/04_captura_requisitos/detalle_cu.md` y `docs/07_implementacion/trazabilidad.md`)
**Actor principal:** Cliente, Encargado de tienda (según `docs/04_captura_requisitos/casos_uso_general.puml` y `docs/04_captura_requisitos/detalle_cu.md`)
**Estado general:** ✅ IMPLEMENTADO

> Nota de trazabilidad: la implementación también está etiquetada como CU11 (`backend/app/api/routes/reservations.py`, `backend/app/models/reservation.py`) y se documenta en CU11. `docs/04_captura_requisitos/detalle_cu.md` indica `PATCH /api/reservas/{id}/estado`; la implementación real usa `PUT /api/reservas/{reserva_id}/estado`.

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Reserva` | `reservas` | `backend/app/models/reservation.py` | `id` (Integer, PK, indexed) · `usuario_id` (Integer, FK `usuarios.id`, nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=False) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `uuid_offline` (String(64), nullable=True, indexed) · `fecha_reserva` (DateTime, nullable=False) · `estado` (String(50), default `"pendiente"`, nullable=False) · `observaciones` (String(255), nullable=True) · relación `detalles` (`DetalleReserva`, backref `reserva`, cascade `all, delete-orphan`) |
| `DetalleReserva` | `detalles_reserva` | `backend/app/models/reservation_detail.py` | `id` (Integer, PK, indexed) · `reserva_id` (Integer, FK `reservas.id`, nullable=False) · `variante_id` (Integer, FK `producto_variantes.id`, nullable=False) · `cantidad` (Integer, default 1, nullable=False) |
| `Inventario` | `inventarios` | `backend/app/models/inventory.py` | `id` (Integer, PK, indexed) · `variante_id` (Integer, FK `producto_variantes.id`, nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=False) · `cantidad` (Integer, default 0, nullable=False) · `cantidad_reservada` (Integer, default 0, nullable=False) · relación `variante` (lazy `joined`) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| GET | `/api/reservas` | `backend/app/api/routes/reservations.py` | ✅ Implementado — lista reservas del usuario autenticado (`estado` opcional) |
| GET | `/api/reservas/admin/todas` | `backend/app/api/routes/reservations.py` | ✅ Implementado — lista reservas de la empresa (admin, filtros `estado`/`sucursal_id`) |
| GET | `/api/reservas/{reserva_id}` | `backend/app/api/routes/reservations.py` | ✅ Implementado — obtiene reserva del usuario |
| POST | `/api/reservas` | `backend/app/api/routes/reservations.py` | ✅ Implementado — crea reserva; valida sucursal/variantes de empresa y stock |
| PUT | `/api/reservas/{reserva_id}/cancelar` | `backend/app/api/routes/reservations.py` | ✅ Implementado — cancela reserva del cliente y libera stock reservado |
| PUT | `/api/reservas/{reserva_id}/estado` | `backend/app/api/routes/reservations.py` | ✅ Implementado — cambia estado (admin): `pendiente`, `confirmada`, `cancelada`, `completada` |

**Servicios / funciones:** `backend/app/services/reservation_service.py` — `listar_reservas_usuario`, `listar_todas_las_reservas`, `obtener_reserva_por_id`, `crear_reserva` (agrupa variantes, verifica stock con bloqueo `with_for_update`, incrementa `cantidad_reservada`, crea notificación al cliente y notifica a sucursal vía `notification_service.notificar_nueva_reserva`), `cancelar_reserva_cliente`, `cambiar_estado_reserva_admin` (confirmar/cancelar/completar ajusta inventario y notifica).

**Necesidades del CU | Estado**

| Necesidad | Estado |
|-----------|--------|
| Registrar reserva con múltiples prendas/variantes (RF09, RF10) | ✅ Implementado — `POST /api/reservas` con detalles |
| Verificar stock en sucursal antes de reservar | ✅ Implementado — `reservation_service.crear_reserva` valida `cantidad - cantidad_reservada` |
| Notificar reserva a sucursal/encargados (RF11) | ✅ Implementado — `notificar_nueva_reserva` en `backend/app/services/notification_service.py` |
| Consultar estado de reserva (RF12) | ✅ Implementado — `GET /api/reservas`, `GET /api/reservas/{id}` |
| Cambiar estado (confirmar/recoger/completar/cancelar) | ✅ Implementado — `PUT /api/reservas/{id}/estado`, `PUT /api/reservas/{id}/cancelar` |

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/reservas` | `frontend/src/app/pages/reservas/reservas.ts` · ruta `/reservas` | ✅ Implementado |
| `pages/admin-operaciones` | `frontend/src/app/pages/admin-operaciones/admin-operaciones.ts` · ruta `/admin/operaciones` | ✅ Implementado — gestión operativa/admin (incluye contexto de operaciones) |

Servicios frontend: `frontend/src/app/core/services/reservas.service.ts`, `frontend/src/app/core/services/sucursales.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/mis_reservas_page.dart` | `mobile/lib/screens/mis_reservas_page.dart` | ✅ Implementado |
| `screens/admin_operaciones_page.dart` | `mobile/lib/screens/admin_operaciones_page.dart` | ✅ Implementado |
| Servicio `services/reservas_service.dart` | `mobile/lib/services/reservas_service.dart` | ✅ Implementado |

**Flujo:** selección de variantes + sucursal + fecha → `POST /api/reservas` (verifica stock, reserva cantidades, notifica) → `GET /api/reservas` / `GET /api/reservas/{id}` → cliente `PUT /api/reservas/{id}/cancelar` o admin `PUT /api/reservas/{id}/estado`.

---

# CU25 — Consultar disponibilidad

**RF asociado:** RF08 — Consultar disponibilidad por sucursal (según `docs/04_captura_requisitos/requisitos.md` y `docs/07_implementacion/trazabilidad.md`)
**Actor principal:** Cliente, Encargado de tienda (según `docs/04_captura_requisitos/casos_uso_general.puml`)
**Estado general:** ✅ IMPLEMENTADO

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Inventario` | `inventarios` | `backend/app/models/inventory.py` | `id` (Integer, PK, indexed) · `variante_id` (Integer, FK `producto_variantes.id`, nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=False) · `cantidad` (Integer, default 0, nullable=False) · `cantidad_reservada` (Integer, default 0, nullable=False) · relación `variante` (relationship `ProductoVariante`, lazy `joined`) |
| `Sucursal` | `sucursales` | `backend/app/models/branch.py` | `id` (Integer, PK, indexed) · `nombre` (String(100), unique, nullable=False) · `direccion` (String(255), nullable=False) · `ciudad` (String(100), nullable=False) · `telefono` (String(30), nullable=True) · `activo` (Boolean, default true, nullable=False) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) |
| `ProductoVariante` | `producto_variantes` | `backend/app/models/product_variant.py` | `id` (Integer, PK, indexed) · `producto_id` (Integer, FK `productos.id`, nullable=False) · `talla_id` (Integer, FK `tallas.id`, nullable=False) · `color_id` (Integer, FK `colores.id`, nullable=False) · `nombre_variante` (String(120), nullable=True) · `imagen_url` (String(500), nullable=True) · `activo` (Boolean, default true, nullable=False) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| GET | `/api/inventario` | `backend/app/api/routes/inventory.py` | ✅ Implementado — consulta stock por `sucursal_id` y/o `variante_id` (filtrado por empresa); base de la disponibilidad por sucursal |
| GET | `/api/inventario/detallado` | `backend/app/api/routes/inventory.py` | ✅ Implementado — vista paginada/enriquecida para consulta operativa/admin |
| GET | `/api/inventario/{inventario_id}` | `backend/app/api/routes/inventory.py` | ✅ Implementado — detalle de registro de inventario |
| GET | `/api/variantes/producto/{producto_id}` | `backend/app/api/routes/product_variants.py` (consumido por UI) | ✅ Implementado — variantes con disponibilidad para selección de compra/reserva (usado por frontend/mobile; ver comentarios RF08 en `frontend/src/app/pages/producto-detalle/producto-detalle.ts`) |

**Servicios / funciones:** `backend/app/services/inventory_service.py` — `listar_inventario`, `listar_inventario_paginado`, `obtener_inventario_por_id` (consultas enriquecidas). `backend/app/services/cart_service.py` — `calcular_stock_disponible` (valida disponibilidad global en sucursales activas al operar carrito). `backend/app/services/reservation_service.py` — verificación de stock disponible por sucursal al reservar.

**Necesidades del CU | Estado**

| Necesidad | Estado |
|-----------|--------|
| Consultar disponibilidad de producto/variante por sucursal (RF08) | ✅ Implementado — `GET /api/inventario` con filtros + datos de variantes |
| Mostrar disponibilidad al cliente en selección de variante | ✅ Implementado — frontend/mobile usan `stock_disponible` de variantes y validan cantidad |
| Soportar decisiones de reserva/compra según stock | ✅ Implementado — validaciones en carrito, pedidos y reservas |

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/producto-detalle` | `frontend/src/app/pages/producto-detalle/producto-detalle.ts` · ruta `/producto/:id` | ✅ Implementado — consulta variantes con `stock_disponible` (`GET /api/variantes/producto/{id}`), controla cantidad y selección disponible (RF08) |
| `pages/admin-inventario` | `frontend/src/app/pages/admin-inventario/admin-inventario.ts` · ruta `/admin/inventario` | ✅ Implementado — consulta operativa de existencias por sucursal |

Servicios frontend: `frontend/src/app/core/services/variantes.service.ts`, `frontend/src/app/core/services/inventario.service.ts`, `frontend/src/app/core/services/sucursales.service.ts`, `frontend/src/app/core/services/productos.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/producto_detalle_page.dart` | `mobile/lib/screens/producto_detalle_page.dart` | ✅ Implementado — muestra stock disponible por variante (`stockDisponible`) y limita cantidad |
| `screens/admin_inventario_page.dart` | `mobile/lib/screens/admin_inventario_page.dart` | ✅ Implementado — consulta/gestión operativa de inventario |
| Servicio `services/inventario_service.dart` | `mobile/lib/services/inventario_service.dart` | ✅ Implementado |

**Flujo:** cliente abre detalle → obtiene variantes (`GET /api/variantes/producto/{id}` con disponibilidad) → selecciona variante/cantidad según stock; operación/admin consulta `GET /api/inventario` por sucursal/variante.

---

# CU16 — Gestionar categorías

**RF asociado:** RF05 — Gestionar tallas, colores, categorías (según `docs/04_captura_requisitos/requisitos.md`; `docs/07_implementacion/trazabilidad.md` mapea CU16 a RF05)
**Actor principal:** Administrador (según `docs/04_captura_requisitos/casos_uso_general.puml`)
**Estado general:** ✅ IMPLEMENTADO

> Nota de trazabilidad: la gestión de categorías forma parte de la administración de catálogo y ya aparece implementada dentro de CU06 (pestaña `categorias` en `frontend/src/app/pages/admin-catalogo/admin-catalogo.ts` y tab correspondiente en `mobile/lib/screens/admin_catalogo_page.dart`). Se documenta aquí para el número PUDS CU16 solicitado.

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Categoria` | `categorias` | `backend/app/models/category.py` | `id` (Integer, PK, indexed) · `nombre` (String(100), unique, nullable=False) · `descripcion` (String(255), nullable=True) · `activo` (Boolean, default true, nullable=False) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| GET | `/api/categorias` | `backend/app/api/routes/categories.py` | ✅ Implementado — lista categorías (`solo_activos` opcional) |
| GET | `/api/categorias/{categoria_id}` | `backend/app/api/routes/categories.py` | ✅ Implementado — obtiene categoría por ID |
| POST | `/api/categorias` | `backend/app/api/routes/categories.py` | ✅ Implementado — crea categoría (solo administrador) |
| PUT | `/api/categorias/{categoria_id}` | `backend/app/api/routes/categories.py` | ✅ Implementado — actualiza categoría (solo administrador) |
| DELETE | `/api/categorias/{categoria_id}` | `backend/app/api/routes/categories.py` | ✅ Implementado — desactiva categoría (`activo=false`, solo administrador) |

**Servicios / funciones:** `backend/app/services/category_service.py` — `listar_categorias`, `obtener_categoria_por_id`, `crear_categoria` (valida nombre único, case-insensitive), `actualizar_categoria`, `eliminar_categoria` (desactivación lógica).

**Necesidades del CU | Estado**

| Necesidad | Estado |
|-----------|--------|
| Listar y consultar categorías | ✅ Implementado |
| Crear, editar y desactivar categorías (admin) | ✅ Implementado |
| Evitar duplicados por nombre | ✅ Implementado — validación en `category_service` |

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/admin-catalogo` (pestaña `categorias`) | `frontend/src/app/pages/admin-catalogo/admin-catalogo.ts` · ruta `/admin/catalogo` | ✅ Implementado |

Servicios frontend: `frontend/src/app/core/services/categorias.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/admin_catalogo_page.dart` (tab `Categorías`) | `mobile/lib/screens/admin_catalogo_page.dart` | ✅ Implementado |
| Servicio `services/catalogo_service.dart` / lógica de catálogo | `mobile/lib/services/catalogo_service.dart` | ✅ Implementado — consumo de recursos de catálogo (según estructura móvil) |

**Flujo:** `GET /api/categorias` → (admin) `POST`/`PUT`/`DELETE /api/categorias/{id}` → refresco de listado en catálogo admin.

---

# CU17 — Gestionar sucursales

**RF asociado:** RF03 — Administrar ciudades y sucursales (según `docs/04_captura_requisitos/requisitos.md` y `docs/07_implementacion/trazabilidad.md`)
**Actor principal:** Administrador (según `docs/04_captura_requisitos/casos_uso_general.puml`)
**Estado general:** ✅ IMPLEMENTADO

> Nota de trazabilidad: la misma implementación ya está documentada como CU05 “Gestionar sucursales” en este archivo (`backend/app/api/routes/branches.py`, pestaña `sucursales` en admin-catalogo web/mobile). Se documenta aquí para el número PUDS CU17 solicitado.

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Sucursal` | `sucursales` | `backend/app/models/branch.py` | `id` (Integer, PK, indexed) · `nombre` (String(100), unique, nullable=False) · `direccion` (String(255), nullable=False) · `ciudad` (String(100), nullable=False) · `telefono` (String(30), nullable=True) · `activo` (Boolean, default true, nullable=False) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) |
| `Empresa` | `empresas` | `backend/app/models/saas.py` | `id` (Integer, PK, indexed) · `nombre` (String(150), unique, nullable=False) · `fecha_registro` (DateTime, default UTC, nullable=False) · `activo` (Boolean, default true, nullable=False) |
| `Suscripcion` | `suscripciones` | `backend/app/models/saas.py` | `id` (Integer, PK, indexed) · `empresa_id` (Integer, FK `empresas.id`, nullable=False, indexed) · `plan_id` (Integer, FK `planes.id`, nullable=False, indexed) · `fecha_inicio` (DateTime, default UTC, nullable=False) · `fecha_fin` (DateTime, nullable) · `estado` (String(20), default "activo", nullable=False) |
| `Plan` | `planes` | `backend/app/models/saas.py` | `id` (Integer, PK, indexed) · `nombre` (String(50), unique, nullable=False) · `max_sucursales` (Integer, default 2, nullable=False) · `permite_ia` (Boolean, default false, nullable=False) · `permite_offline` (Boolean, default false, nullable=False) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| GET | `/api/sucursales` | `backend/app/api/routes/branches.py` | ✅ Implementado — lista sucursales por `empresa_id` (`solo_activos` opcional) |
| GET | `/api/sucursales/{sucursal_id}` | `backend/app/api/routes/branches.py` | ✅ Implementado — obtiene sucursal de la empresa |
| POST | `/api/sucursales` | `backend/app/api/routes/branches.py` | ✅ Implementado — crea sucursal (admin); valida límite de sucursales del plan activo (RN-SaaS-01) |
| PUT | `/api/sucursales/{sucursal_id}` | `backend/app/api/routes/branches.py` | ✅ Implementado — actualiza sucursal (admin) |
| DELETE | `/api/sucursales/{sucursal_id}` | `backend/app/api/routes/branches.py` | ✅ Implementado — desactiva sucursal (admin) |

**Servicios / funciones:** `backend/app/services/branch_service.py` — `listar_sucursales`, `actualizar_sucursal`, `eliminar_sucursal`. La validación de alta (nombre único, pertenencia empresa, límite por plan/suscripción activa) se realiza en `backend/app/api/routes/branches.py` consultando `Sucursal`, `Suscripcion` y `Plan`.

**Necesidades del CU | Estado**

| Necesidad | Estado |
|-----------|--------|
| Administrar sucursales (alta, edición, desactivación) | ✅ Implementado |
| Restringir sucursales al tenant/empresa | ✅ Implementado — filtro por `empresa_id` |
| Respetar límite de sucursales según plan (SaaS) | ✅ Implementado — validación en `POST /api/sucursales` |

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/admin-catalogo` (pestaña `sucursales`) | `frontend/src/app/pages/admin-catalogo/admin-catalogo.ts` · ruta `/admin/catalogo` | ✅ Implementado |
| `pages/punto-venta` · `pages/carrito` · `pages/checkout` · `pages/reservas` · `pages/admin-inventario` · `pages/admin-operaciones` | selección/uso de sucursal | ✅ Implementado |

Servicios frontend: `frontend/src/app/core/services/sucursales.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/admin_catalogo_page.dart` (tab `Sucursales`) | `mobile/lib/screens/admin_catalogo_page.dart` | ✅ Implementado |
| Servicio `services/sucursales_service.dart` | `mobile/lib/services/sucursales_service.dart` | ✅ Implementado |

**Flujo:** `GET /api/sucursales` → (admin) `POST`/`PUT`/`DELETE /api/sucursales/{id}` (alta sujeta a plan) → sucursales disponibles en inventario, ventas, reservas y compras.

---

# CU18 — Administrar venta de producto

**RF asociado:** RF17 — Registrar ventas presenciales (según `docs/04_captura_requisitos/requisitos.md` y `docs/07_implementacion/trazabilidad.md`)
**Actor principal:** Cajero (según `docs/04_captura_requisitos/casos_uso_general.puml`; la implementación restringe la ruta a rol `administrador` en `backend/app/api/routes/orders.py`)
**Estado general:** ✅ IMPLEMENTADO

> Nota de trazabilidad: coincide con la implementación documentada como CU10 “Gestionar ventas presenciales” (`POST /api/pedidos/venta-presencial`, `frontend/src/app/pages/punto-venta`, `mobile/lib/screens/punto_venta_page.dart`). CU20 “Realizar nota de venta” se apoya en esta misma venta y en la generación/visualización de comprobante. Se documenta aquí para el número PUDS CU18 solicitado.

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Pedido` | `pedidos` | `backend/app/models/order.py` | `id` (Integer, PK, indexed) · `usuario_id` (Integer, FK `usuarios.id`, nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=True) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `uuid_offline` (String(64), nullable=True, indexed) · `fecha_pedido` (DateTime, default `datetime.utcnow`, nullable=False) · `estado` (String(50), default `"pendiente"`, nullable=False) · `total` (Numeric(10,2), default 0, nullable=False) · relación `detalles` (`DetallePedido`, backref `pedido`, cascade `all, delete-orphan`) |
| `DetallePedido` | `detalles_pedido` | `backend/app/models/order_detail.py` | `id` (Integer, PK, indexed) · `pedido_id` (Integer, FK `pedidos.id`, nullable=False) · `variante_id` (Integer, FK `producto_variantes.id`, nullable=False) · `cantidad` (Integer, nullable=False) · `precio_unitario` (Numeric(10,2), nullable=False) · `subtotal` (Numeric(10,2), nullable=False) |
| `Pago` | `pagos` | `backend/app/models/payment.py` | `id` (Integer, PK, indexed) · `pedido_id` (Integer, FK `pedidos.id`, nullable=False) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `metodo` (String(30), nullable=False) · `monto` (Numeric(10,2), nullable=False) · `estado` (String(30), default `"pendiente"`, nullable=False) · `referencia` (String(150), nullable=True) · `fecha_pago` (DateTime, nullable=True) |
| `Inventario` | `inventarios` | `backend/app/models/inventory.py` | `id` (Integer, PK, indexed) · `variante_id` (Integer, FK `producto_variantes.id`, nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=False) · `cantidad` (Integer, default 0, nullable=False) · `cantidad_reservada` (Integer, default 0, nullable=False) · relación `variante` (lazy `joined`) |
| `Usuario` | `usuarios` | `backend/app/models/user.py` | `id` (Integer, PK, indexed) · `nombre` (String(100), nullable=False) · `apellido` (String(100), nullable=False) · `email` (String(150), unique, indexed, nullable=False) · `password_hash` (String(255), nullable=False) · `activo` (Boolean, default true, nullable=False) · `rol` (String(30), default "cliente", nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=True, indexed) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `fecha_creacion` (DateTime, default UTC, nullable=False) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| POST | `/api/pedidos/venta-presencial` | `backend/app/api/routes/orders.py` | ✅ Implementado — registra venta presencial (rol `administrador`); valida sucursal/empresa, ítems/variantes, stock, crea pedido `pagado`, descuenta inventario y registra pago aprobado |
| GET | `/api/pedidos/admin/todos` | `backend/app/api/routes/orders.py` | ✅ Implementado — consulta ventas/pedidos de la empresa (admin) |
| PUT | `/api/pedidos/{pedido_id}/estado` | `backend/app/api/routes/orders.py` | ✅ Implementado — administra estado del pedido/venta (admin) |

**Servicios / funciones:** `backend/app/services/order_service.py` — `crear_venta_presencial` (valida cliente, sucursal activa, método de pago contra tipos activos, stock por sucursal; genera `Pedido`, `DetallePedido`, descuenta `Inventario`, crea `Pago` aprobado y notificación), `listar_todos_los_pedidos`, `cambiar_estado_pedido_admin`. Apoya validación de métodos: `backend/app/services/payment_type_service.py` — `nombres_tipos_pago_activos`.

**Necesidades del CU | Estado**

| Necesidad | Estado |
|-----------|--------|
| Registrar venta presencial de productos (RF17) | ✅ Implementado — `POST /api/pedidos/venta-presencial` |
| Validar cliente, sucursal, variantes y stock | ✅ Implementado — `orders.py` + `order_service.crear_venta_presencial` |
| Descontar inventario de la sucursal al vender | ✅ Implementado — decremento en `crear_venta_presencial` |
| Registrar pago en punto de caja asociado a la venta | ✅ Implementado — crea `Pago` aprobado (relación con CU19/RF18) |
| Permitir operación por rol Cajero específico | ⚠️ PARCIAL — la ruta exige `requerir_rol("administrador")`; no se observa un rol/permiso `cajero` dedicado en esta ruta |

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/punto-venta` | `frontend/src/app/pages/punto-venta/punto-venta.ts` · ruta `/admin/punto-venta` | ✅ Implementado |
| `pages/admin-operaciones` | `frontend/src/app/pages/admin-operaciones/admin-operaciones.ts` · ruta `/admin/operaciones` | ✅ Implementado — seguimiento operativo de pedidos/ventas |
| `shared/recibo/recibo` | `frontend/src/app/shared/recibo/recibo.ts` | ✅ Implementado — comprobante/recibo visual usado desde punto de venta, operaciones y pedidos |

Servicios frontend: `frontend/src/app/core/services/pedidos.service.ts`, `frontend/src/app/core/services/pagos.service.ts`, `frontend/src/app/core/services/usuarios.service.ts`, `frontend/src/app/core/services/sucursales.service.ts`, `frontend/src/app/core/services/productos.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/punto_venta_page.dart` | `mobile/lib/screens/punto_venta_page.dart` | ✅ Implementado |
| Servicio `services/pedidos_service.dart` | `mobile/lib/services/pedidos_service.dart` | ✅ Implementado |

**Flujo:** selección de cliente + sucursal + ítems → validación de stock/precios → `POST /api/pedidos/venta-presencial` → pedido `pagado` + pago aprobado + descuento de inventario → visualización de recibo/comprobante en UI.

---

# CU19 — Administrar tipo de pago

**RF asociado:** RF18, RF19 — Pagos en punto de caja / Integrar pasarela de pago (según `docs/04_captura_requisitos/requisitos.md` y `docs/07_implementacion/trazabilidad.md`)
**Actor principal:** Administrador, Cajero (según `docs/04_captura_requisitos/casos_uso_general.puml`)
**Estado general:** ✅ IMPLEMENTADO

> Nota de trazabilidad: el catálogo de tipos de pago está implementado en `backend/app/api/routes/payment_types.py` (etiquetado CU19). El procesamiento/pasarela de pago se implementa en `backend/app/api/routes/payments.py` y `backend/app/services/{payment_service,stripe_service}.py`, también documentado como CU26 “Procesar pago” en este archivo. `payments.py` contiene definiciones duplicadas de rutas Stripe (`/stripe/config`, `/stripe/intent`, `/stripe/confirm`) en el código real; se documenta el estado observado.

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `TipoPago` | `tipos_pago` | `backend/app/models/payment_type.py` | `id` (Integer, PK, indexed) · `nombre` (String(30), unique, nullable=False) · `activo` (Boolean, default true, nullable=False) |
| `Pago` | `pagos` | `backend/app/models/payment.py` | `id` (Integer, PK, indexed) · `pedido_id` (Integer, FK `pedidos.id`, nullable=False) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `metodo` (String(30), nullable=False) · `monto` (Numeric(10,2), nullable=False) · `estado` (String(30), default `"pendiente"`, nullable=False) · `referencia` (String(150), nullable=True) · `fecha_pago` (DateTime, nullable=True) |
| `Pedido` | `pedidos` | `backend/app/models/order.py` | `id` (Integer, PK, indexed) · `usuario_id` (Integer, FK `usuarios.id`, nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=True) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `uuid_offline` (String(64), nullable=True, indexed) · `fecha_pedido` (DateTime, default `datetime.utcnow`, nullable=False) · `estado` (String(50), default `"pendiente"`, nullable=False) · `total` (Numeric(10,2), default 0, nullable=False) · relación `detalles` (`DetallePedido`, cascade `all, delete-orphan`) |

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| GET | `/api/tipos-pago` | `backend/app/api/routes/payment_types.py` | ✅ Implementado — lista tipos de pago (`solo_activos` opcional, default `true`) |
| POST | `/api/tipos-pago` | `backend/app/api/routes/payment_types.py` | ✅ Implementado — crea tipo de pago (solo administrador) |
| PUT | `/api/tipos-pago/{tipo_pago_id}` | `backend/app/api/routes/payment_types.py` | ✅ Implementado — actualiza tipo de pago (solo administrador) |
| DELETE | `/api/tipos-pago/{tipo_pago_id}` | `backend/app/api/routes/payment_types.py` | ✅ Implementado — desactiva tipo de pago (solo administrador) |

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| POST | `/api/pagos` | `backend/app/api/routes/payments.py` | ✅ Implementado — registra pago de pedido (punto de caja/digital, validaciones de empresa/monto) |
| GET | `/api/pagos/pedido/{pedido_id}` | `backend/app/api/routes/payments.py` | ✅ Implementado — lista pagos del pedido |
| GET | `/api/pagos/stripe/config` | `backend/app/api/routes/payments.py` | ✅ Implementado — configuración pública Stripe (RF19); **observación:** handler duplicado en el mismo archivo |
| POST | `/api/pagos/stripe/intent` | `backend/app/api/routes/payments.py` | ✅ Implementado — crea `PaymentIntent` (RF19); **observación:** handler duplicado en el mismo archivo |
| POST | `/api/pagos/stripe/confirm` | `backend/app/api/routes/payments.py` | ✅ Implementado — confirma `PaymentIntent`; **observación:** handler duplicado en el mismo archivo |
| POST | `/api/pagos/stripe/webhook` | `backend/app/api/routes/payments.py` | ✅ Implementado — recibe eventos Stripe |

**Servicios / funciones:** `backend/app/services/payment_type_service.py` — `listar_tipos_pago`, `obtener_tipo_pago_por_id`, `nombres_tipos_pago_activos`, `crear_tipo_pago`, `actualizar_tipo_pago`, `eliminar_tipo_pago`. `backend/app/services/payment_service.py` — `registrar_pago` (valida estado del pedido, monto exacto, método/tipo activo o simulados `tarjeta`/`qr`/`efectivo`; aprueba pago y marca pedido `pagado`), `listar_pagos_pedido`. `backend/app/services/stripe_service.py` — `obtener_config_publica`, `crear_payment_intent`, `confirmar_pago`, `procesar_webhook`. `order_service.crear_venta_presencial` valida método contra tipos activos.

**Necesidades del CU | Estado**

| Necesidad | Estado |
|-----------|--------|
| Administrar catálogo de tipos/métodos de pago (RF18) | ✅ Implementado — `/api/tipos-pago` + `payment_type_service` |
| Permitir pago en punto de caja | ✅ Implementado — `POST /api/pagos` y venta presencial con pago aprobado |
| Integrar pasarela de pago para compras digitales (RF19) | ✅ Implementado — endpoints Stripe + `stripe_service` |
| Usar tipos de pago activos en flujos de cobro | ✅ Implementado — validación en `payment_service` y `order_service` |

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `pages/admin-configuracion` (pestaña `tipos-pago`) | `frontend/src/app/pages/admin-configuracion/admin-configuracion.ts` · ruta `/admin/configuracion` | ✅ Implementado |
| `pages/checkout` | `frontend/src/app/pages/checkout/checkout.ts` · ruta `/checkout/:pedidoId` | ✅ Implementado — cobro digital |
| `pages/punto-venta` | `frontend/src/app/pages/punto-venta/punto-venta.ts` · ruta `/admin/punto-venta` | ✅ Implementado — cobro en caja |
| `pages/pedidos` | `frontend/src/app/pages/pedidos/pedidos.ts` · ruta `/pedidos` | ✅ Implementado — pagos/estado de pedidos |

Servicios frontend: `frontend/src/app/core/services/tipos-pago.service.ts`, `frontend/src/app/core/services/pagos.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/tipos_pago_page.dart` | `mobile/lib/screens/tipos_pago_page.dart` | ✅ Implementado |
| `screens/punto_venta_page.dart` | `mobile/lib/screens/punto_venta_page.dart` | ✅ Implementado |
| `screens/pago_qr_page.dart` | `mobile/lib/screens/pago_qr_page.dart` | ✅ Implementado |
| Servicio `services/tipos_pago_service.dart` | `mobile/lib/services/tipos_pago_service.dart` | ✅ Implementado |
| Servicio `services/stripe_service.dart` | `mobile/lib/services/stripe_service.dart` | ✅ Implementado |

**Flujo:** admin gestiona tipos (`GET/POST/PUT/DELETE /api/tipos-pago`) → venta/checkout selecciona método activo → caja: `POST /api/pagos` o venta presencial con pago aprobado; digital: `GET /api/pagos/stripe/config` → `POST /api/pagos/stripe/intent` → confirmación/webhook Stripe.

---

# CU20 — Realizar nota de venta

**RF asociado:** RF17 — Registrar ventas presenciales (según `docs/04_captura_requisitos/requisitos.md` y `docs/07_implementacion/trazabilidad.md`)
**Actor principal:** Cajero (según `docs/04_captura_requisitos/casos_uso_general.puml`)
**Estado general:** ⚠️ PARCIAL

> Nota de trazabilidad: en el código backend no existe un modelo/ruta específica de “nota de venta”; `backend/app/api/routes/payments.py` indica que la nota de venta (CU20) corresponde al comprobante compuesto por el detalle de pago/pedido. La venta que origina la nota se implementa como CU18/CU10 (`POST /api/pedidos/venta-presencial`, `order_service.crear_venta_presencial`). El comprobante visual se implementa en frontend con `ReciboComponent`.

## 1. Modelos / tablas del backend

| Modelo | Tabla | Archivo | Atributos |
|--------|-------|---------|-----------|
| `Pedido` | `pedidos` | `backend/app/models/order.py` | `id` (Integer, PK, indexed) · `usuario_id` (Integer, FK `usuarios.id`, nullable=False) · `sucursal_id` (Integer, FK `sucursales.id`, nullable=True) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `uuid_offline` (String(64), nullable=True, indexed) · `fecha_pedido` (DateTime, default `datetime.utcnow`, nullable=False) · `estado` (String(50), default `"pendiente"`, nullable=False) · `total` (Numeric(10,2), default 0, nullable=False) · relación `detalles` (`DetallePedido`, backref `pedido`, cascade `all, delete-orphan`) |
| `DetallePedido` | `detalles_pedido` | `backend/app/models/order_detail.py` | `id` (Integer, PK, indexed) · `pedido_id` (Integer, FK `pedidos.id`, nullable=False) · `variante_id` (Integer, FK `producto_variantes.id`, nullable=False) · `cantidad` (Integer, nullable=False) · `precio_unitario` (Numeric(10,2), nullable=False) · `subtotal` (Numeric(10,2), nullable=False) |
| `Pago` | `pagos` | `backend/app/models/payment.py` | `id` (Integer, PK, indexed) · `pedido_id` (Integer, FK `pedidos.id`, nullable=False) · `empresa_id` (Integer, FK `empresas.id`, nullable=True, indexed) · `metodo` (String(30), nullable=False) · `monto` (Numeric(10,2), nullable=False) · `estado` (String(30), default `"pendiente"`, nullable=False) · `referencia` (String(150), nullable=True) · `fecha_pago` (DateTime, nullable=True) |

> No existe un modelo/tabla dedicada de nota de venta (`NotaVenta`/`Recibo`/comprobante) en `backend/app/models`.

## 2. Rutas del backend

| Método | Ruta | Archivo | Estado |
|--------|------|---------|--------|
| POST | `/api/pedidos/venta-presencial` | `backend/app/api/routes/orders.py` | ✅ Implementado — genera la venta/pedido base para el comprobante (CU18) |
| GET | `/api/pedidos/{pedido_id}` | `backend/app/api/routes/orders.py` | ✅ Implementado — consulta datos del pedido/venta (usuario) |
| GET | `/api/pedidos/admin/todos` | `backend/app/api/routes/orders.py` | ✅ Implementado — consulta administrativa de pedidos/ventas |
| GET | `/api/pagos/pedido/{pedido_id}` | `backend/app/api/routes/payments.py` | ✅ Implementado — consulta pagos asociados al pedido (detalle de comprobante, CU20 según comentario en ruta) |
| POST | `/api/pagos` | `backend/app/api/routes/payments.py` | ✅ Implementado — registra pago asociado al pedido |

**Servicios / funciones:** `backend/app/services/order_service.py` — `crear_venta_presencial`, `obtener_pedido_por_id`, `listar_todos_los_pedidos`. `backend/app/services/payment_service.py` — `registrar_pago`, `listar_pagos_pedido`. No hay servicio dedicado `nota_venta_service`/generación de documento fiscal o endpoint específico de nota de venta.

**Necesidades del CU | Estado**

| Necesidad | Estado |
|-----------|--------|
| Generar registro de venta que respalde la nota (RF17) | ✅ Implementado — pedido/pago de venta presencial |
| Emitir/visualizar comprobante (nota de venta/recibo) | ⚠️ PARCIAL — existe `ReciboComponent` en frontend (`frontend/src/app/shared/recibo/recibo.ts`) usado en punto de venta, operaciones y pedidos; no hay endpoint/modelo backend dedicado de nota de venta ni generación de documento formal (PDF/fiscal) en backend |
| Consultar detalle de venta y pago para el comprobante | ✅ Implementado — endpoints de pedidos y pagos |

## 3. Pantallas del frontend

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `shared/recibo/recibo` | `frontend/src/app/shared/recibo/recibo.ts` (+ `recibo.html`, `recibo.css`) | ✅ Implementado — componente de recibo/comprobante |
| `pages/punto-venta` | `frontend/src/app/pages/punto-venta/punto-venta.ts` · ruta `/admin/punto-venta` | ✅ Implementado — usa `ReciboComponent` tras venta |
| `pages/admin-operaciones` | `frontend/src/app/pages/admin-operaciones/admin-operaciones.ts` · ruta `/admin/operaciones` | ✅ Implementado — usa `ReciboComponent` |
| `pages/pedidos` | `frontend/src/app/pages/pedidos/pedidos.ts` · ruta `/pedidos` | ✅ Implementado — usa `ReciboComponent` |

Servicios frontend: `frontend/src/app/core/services/pedidos.service.ts`, `frontend/src/app/core/services/pagos.service.ts`.

## 4. Pantallas del mobile

| Pantalla / componente | Ruta / archivo | Estado |
|----------------------|----------------|--------|
| `screens/punto_venta_page.dart` | `mobile/lib/screens/punto_venta_page.dart` | ⚠️ PARCIAL — registra venta presencial; no se verificó un componente/pantalla dedicada de nota de venta/recibo equivalente al `ReciboComponent` web |
| Servicio `services/pedidos_service.dart` | `mobile/lib/services/pedidos_service.dart` | ✅ Implementado |

**Flujo:** `POST /api/pedidos/venta-presencial` (genera venta + pago) → consulta `GET /api/pedidos/{id}` y/o `GET /api/pagos/pedido/{id}` → UI renderiza comprobante con `ReciboComponent` (frontend).

---
