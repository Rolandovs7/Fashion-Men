# 📋 Alcance del Proyecto - Fashion Men

## 1. Alcance Funcional (INCLUIDO)

### 1.1 Gestión de Usuarios
- Registro de clientes, login JWT, roles (cliente/administrador), permisos granulares

### 1.2 Catálogo de Productos
- CRUD de productos, categorías, tallas, colores, marcas, tipos de prenda, temporadas, colecciones, imágenes, descuentos

### 1.3 Inventario Multi-Sucursal
- Control de stock por variante, stock por sucursal, movimientos, alertas de stock bajo

### 1.4 Reservas
- Reserva de varias prendas, selección de sucursal, estados (pendiente, preparada, recogida, cancelada), notificaciones

### 1.5 Carrito y Pedidos
- Carrito, checkout web/móvil, estados de pedido, historial

### 1.6 Pagos
- Métodos configurables, pago en caja, pago electrónico (Stripe), registro

### 1.7 Reportes y Dashboard
- KPIs, top productos, ventas por mes, ventas por método de pago, alertas inventario, ventas por sucursal

### 1.8 Inteligencia Artificial
- Recomendador personalizado, chatbot (reglas + Gemini), tendencias

## 2. Alcance No Funcional

### 2.1 Seguridad
- Contraseñas con bcrypt, JWT con expiración, permisos por rol, .env protegido

### 2.2 Rendimiento
- Respuestas <500ms, paginación, índices en BD

### 2.3 Disponibilidad
- API 24/7 (nube), web responsive, Flutter multiplataforma

### 2.4 Escalabilidad
- Arquitectura por capas, migraciones Alembic, Docker

### 2.5 Usabilidad
- UI intuitiva, Swagger, mensajes claros

## 3. FUERA del Alcance

- ❌ Sistema de delivery (mencionado en PDF, no en RF)
- ❌ i18n / multi-idioma
- ❌ Chatbot con voz (mencionado, no obligatorio)
- ❌ Reportes generativos con IA
- ❌ App iOS nativa
- ❌ Redes sociales / fidelización / wishlist
- ❌ Pagos reales / PCI-DSS completo

## 4. Entregables

- **Código:** backend/, frontend/, mobile/
- **Docs PUDS:** 5 fases completas
- **UML 2.5+:** casos uso, clases, secuencia, componentes, despliegue
- **Fundamentación:** e-commerce, pasarelas, delivery, PUDS, UML
- **Demo:** desplegada en nube

## 5. Criterios de Éxito

- ✅ 25 RF implementados
- ✅ 9 RNF cumplidos
- ✅ 33 CU documentados
- ✅ UML 2.5+ completo
- ✅ 5 fases PUDS
- ✅ Deploy nube
- ✅ MVP demo

---

**Versión:** 1.0
