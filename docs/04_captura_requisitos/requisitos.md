# 📋 Requisitos - Fashion Men

## 1. Requisitos Funcionales (RF)

### 1.1 Gestión de Usuarios
| RF | Descripción | CU | Estado |
|----|-------------|-----|--------|
| RF01 | Registrar clientes | CU01-CU03 | ✅ |
| RF02 | Gestionar usuarios y roles | CU04-CU06 | ✅ |
| RF03 | Administrar ciudades y sucursales | CU17 | ✅ |
| RF04 | Gestionar productos de ropa | CU07, CU10, CU13 | ✅ |
| RF05 | Gestionar tallas, colores, categorías | CU08, CU11, CU12, CU16 | ✅ |
| RF06 | Gestionar proveedores | CU26 | ✅ |

### 1.2 Catálogo
| RF | Descripción | CU | Estado |
|----|-------------|-----|--------|
| RF07 | Consultar catálogo web y móvil | CU14 | ✅ |
| RF08 | Consultar disponibilidad por sucursal | CU25 | ✅ |

### 1.3 Reservas
| RF | Descripción | CU | Estado |
|----|-------------|-----|--------|
| RF09 | Seleccionar múltiples prendas | CU24 | ✅ |
| RF10 | Registrar y gestionar reservas | CU24 | ✅ |
| RF11 | Notificar reservas a sucursal | CU24 | ✅ |
| RF12 | Consultar estado de reserva | CU24 | ✅ |

### 1.4 Compras
| RF | Descripción | CU | Estado |
|----|-------------|-----|--------|
| RF13 | Vestidor virtual (RA) | CU23 | 🚧 |
| RF14 | Agregar productos al carrito | CU22 | ✅ |
| RF15 | Comprar desde web | CU21 | ✅ |
| RF16 | Comprar desde app móvil | CU21 | ✅ |
| RF17 | Registrar ventas presenciales | CU18, CU20 | ✅ |
| RF18 | Pagos en punto de caja | CU19 | ✅ |
| RF19 | Integrar pasarela de pago | CU19 | 🚧 |

### 1.5 Inventario
| RF | Descripción | CU | Estado |
|----|-------------|-----|--------|
| RF20 | Actualizar inventario automáticamente | CU15 | ✅ |
| RF21 | Controlar existencias por sucursal | CU15 | ✅ |
| RF22 | Registrar movimientos | CU15 | ✅ |
| RF23 | Gestionar temporadas y colecciones | CU27, CU28 | ✅ |

### 1.6 Reportes e IA
| RF | Descripción | CU | Estado |
|----|-------------|-----|--------|
| RF24 | Reportes de ventas e inventario | CU29, CU30 | ✅ |
| RF25 | Funcionalidad basada en IA | CU31, CU32 | ✅ |

## 2. Requisitos No Funcionales

| RNF | Descripción | Cómo se cumple |
|-----|-------------|----------------|
| RNF01 | Seguridad | bcrypt + JWT + .env |
| RNF02 | Rendimiento | Índices + paginación |
| RNF03 | Disponibilidad | Deploy nube |
| RNF04 | Escalabilidad | Capas + Docker |
| RNF05 | Usabilidad | UI responsive + Swagger |
| RNF06 | Mantenibilidad | Services + Schemas |
| RNF07 | API REST | FastAPI |
| RNF08 | Flutter/Dart | Flutter 3.47.2 |
| RNF09 | Seguridad transaccional | Stripe sandbox |

## 3. Cobertura

- **RF implementados:** 23/25 (92%)
- **RF en desarrollo:** 2 (RF13, RF19)
- **RNF cumplidos:** 9/9 (100%)

---

**Versión:** 1.0
