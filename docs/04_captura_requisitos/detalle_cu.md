# 📋 Especificación de Casos de Uso - Fashion Men

**Notación:** UML 2.5+
**Formato:** Plantilla estándar (precondiciones, flujo normal, flujos alternativos)

---

## CU01 - Administrar Inicio de Sesión

| Campo | Valor |
|-------|-------|
| **Código** | CU01 |
| **Nombre** | Administrar Inicio de Sesión |
| **Actor principal** | Cliente, Administrador |
| **RF asociado** | RF01 |
| **Prioridad** | Alta |
| **Precondición** | Usuario registrado y activo |
| **Postcondición** | Usuario autenticado con token JWT |

### Flujo Normal
1. Usuario ingresa email y contraseña
2. Sistema valida formato de email
3. Sistema busca usuario por email
4. Sistema verifica contraseña (bcrypt)
5. Sistema genera token JWT (expira 30 min)
6. Sistema retorna `access_token`
7. Usuario es redirigido a su panel

### Flujos Alternativos
- **3a.** Email no existe → Error 401
- **4a.** Contraseña incorrecta → Error 401
- **4b.** Usuario inactivo → Error 401

### Endpoint
`POST /api/auth/login`

---

## CU14 - Administrar Catálogo

| Campo | Valor |
|-------|-------|
| **Código** | CU14 |
| **Nombre** | Administrar Catálogo |
| **Actor principal** | Cliente |
| **RF asociado** | RF07 |
| **Prioridad** | Alta |
| **Precondición** | Productos activos en la BD |
| **Postcondición** | Lista de productos mostrada |

### Flujo Normal
1. Cliente accede a "Catálogo"
2. Sistema consulta productos activos
3. Sistema aplica filtros (categoría, talla, color, marca)
4. Sistema calcula precio con descuentos
5. Sistema retorna lista paginada
6. Cliente visualiza productos

### Flujos Alternativos
- **2a.** No hay productos → "Sin resultados"
- **3a.** Filtros vacíos → Ignorar
- **5a.** Error BD → Error 500

### Endpoints
`GET /api/productos/` · `GET /api/productos/{id}`

---

## CU24 - Gestionar Reservas

| Campo | Valor |
|-------|-------|
| **Código** | CU24 |
| **Nombre** | Gestionar Reservas |
| **Actor principal** | Cliente, Encargado |
| **RF asociado** | RF09, RF10, RF11, RF12 |
| **Prioridad** | Alta |
| **Precondición** | Cliente autenticado + stock |
| **Postcondición** | Reserva creada (estado "pendiente") |

### Flujo Normal
1. Cliente selecciona prendas (variantes)
2. Cliente selecciona sucursal
3. Cliente selecciona fecha/hora
4. Sistema verifica stock
5. Sistema incrementa `cantidad_reservada`
6. Sistema genera reserva "pendiente"
7. Sistema notifica a sucursal
8. Cliente prueba prendas en tienda
9. Encargado marca "recogida" o "cancelada"
10. Sistema libera stock reservado

### Flujos Alternativos
- **4a.** Stock insuficiente → Error
- **8a.** Cliente no acude → Expira 24h
- **9a.** Cliente cancela → Libera stock

### Endpoints
`POST /api/reservas/` · `GET /api/reservas/me` · `PATCH /api/reservas/{id}/estado`

---

## CU32 - Interactuar con Asistente Virtual (IA)

| Campo | Valor |
|-------|-------|
| **Código** | CU32 |
| **Nombre** | Interactuar con Asistente Virtual |
| **Actor principal** | Cliente |
| **Actores secundarios** | Servicio de IA (Gemini) |
| **RF asociado** | RF25 |
| **Prioridad** | Media-Alta |
| **Precondición** | Ninguna (público) |
| **Postcondición** | Respuesta mostrada |

### Flujo Normal
1. Cliente escribe mensaje
2. Sistema envía al `IAService`
3. Servicio aplica reglas rápidas
4. Si hay match → respuesta inmediata
5. Si no → consulta a Gemini
6. Gemini retorna respuesta
7. Sistema retorna `{respuesta, productos_sugeridos, fuente}`
8. Cliente visualiza

### Flujos Alternativos
- **5a.** Gemini no disponible → Fallback
- **5b.** Timeout → Fallback
- **6a.** Sin API key → Saltar

### Endpoint
`POST /api/ia/chat` con body `{"mensaje": "string"}`

---

## Resumen

| CU | Nombre | Actor | RF |
|----|--------|-------|-----|
| CU01 | Administrar Inicio de Sesión | Cliente, Admin | RF01 |
| CU14 | Administrar Catálogo | Cliente | RF07 |
| CU24 | Gestionar Reservas | Cliente, Encargado | RF09-RF12 |
| CU32 | Interactuar Asistente Virtual | Cliente | RF25 |

> Los 33 CU están documentados en `docs/05_implementacion/trazabilidad.md`

---

**Versión:** 1.0
