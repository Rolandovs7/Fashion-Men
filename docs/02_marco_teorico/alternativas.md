# 2.5 - Alternativas de Cambio

## 1. Matriz de Soluciones

| Problema | Alternativa de Cambio | Módulo del Sistema |
|----------|----------------------|--------------------|
| P1 | Plataforma centralizada con BD única | Backend + BD |
| P2 | Inventario con actualización automática | CU15, CU20 |
| P3 | Consulta de disponibilidad en tiempo real | CU25 |
| P4 | Reservas digitales con notificaciones | CU24 |
| P5 | Gestión unificada de ventas (web/móvil/POS) | CU18, CU21 |
| P6 | Módulo de pagos + pasarela Stripe | CU19 |
| P7 | Gestión de proveedores y órdenes | CU26 |
| P8 | Registro de movimientos de inventario | CU15 |
| P9 | Catálogo estructurado por temporadas | CU07-CU17 |
| P10 | Dashboard + reportes automáticos | CU29, CU30 |
| P11 | Auth con roles, permisos y bitácora | CU01-CU06 |
| P12 | Vestidor virtual (RA) + IA | CU23, CU31, CU32 |

## 2. Priorización de Alternativas

### Ciclo de Vida #1 - Base (Obligatorio)
- **C1:** Autenticación y seguridad (P11)
- **C2:** Gestión de usuarios y roles (P11)

### Ciclo de Vida #2 - Core del Negocio
- **C3:** Catálogo estructurado (P9)
- **C4:** Inventario multi-sucursal (P2, P3, P8)
- **C5:** Proveedores (P7)

### Ciclo de Vida #3 - Comercial
- **C6:** Ventas y pagos (P5, P6)
- **C7:** Reservas (P4)
- **C8:** Pedidos y carrito (P5)

### Ciclo de Vida #4 - Innovación
- **C9:** Vestidor virtual con RA (P12)
- **C10:** Reportes y dashboard (P10)
- **C11:** IA para recomendaciones (P12)

## 3. Conclusión

La solución se implementará en **4 ciclos de vida** (iteraciones del PUDS), 
cubriendo los 12 problemas identificados con los 33 casos de uso definidos.

Cada ciclo entrega un **incremento funcional** del sistema.
