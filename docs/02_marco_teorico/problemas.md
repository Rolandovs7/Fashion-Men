# 2.1 - Identificación y Análisis de Problemas

## 1. Lista Inicial de Problemas

| # | Problema | Categoría |
|---|----------|-----------|
| P1 | Información de productos, clientes y sucursales dispersa, sin base centralizada | Gestión de Información |
| P2 | Descontrol del inventario por sucursal, talla, color y temporada | Inventario |
| P3 | Dificultad para conocer disponibilidad real de una prenda en sucursal | Inventario |
| P4 | Proceso manual y desorganizado de reservas | Ventas |
| P5 | Ventas web, móvil y presenciales registradas por separado | Integración |
| P6 | Pagos electrónicos y presenciales sin control unificado | Pagos |
| P7 | Gestión deficiente de proveedores y recepción de mercadería | Abastecimiento |
| P8 | Falta de trazabilidad en movimientos de inventario | Trazabilidad |
| P9 | Catálogo desorganizado (productos, tallas, colores, temporadas) | Catálogo |
| P10 | Ausencia de reportes consolidados para análisis | Análisis |
| P11 | Control débil sobre usuarios, roles y permisos | Seguridad |
| P12 | El cliente no puede evaluar prendas a distancia ni recibir recomendaciones | Experiencia |

## 2. Depuración de Problemas

Se descartan o re-clasifican:

- **P5:** Se aborda como parte de la solución integral (no como problema aislado)
- **P7:** Se incluye parcialmente (depende de factores externos)
- **P12:** Es oportunidad de innovación, no problema crítico

## 3. Lista Final de Problemas

Los 12 problemas se mantienen para el análisis, pero se priorizan:

### Prioridad Alta
- P2, P3 (Inventario)
- P4, P5, P6 (Ventas)
- P8, P11 (Seguridad/Trazabilidad)

### Prioridad Media
- P1, P9, P10 (Información)

### Prioridad Innovación
- P7 (Abastecimiento)
- P12 (Experiencia cliente)

## 4. Propietarios de Problemas

| Problema | Admin | Encargado | Cajero | Cliente | Proveedor |
|----------|-------|-----------|--------|---------|-----------|
| P1 - Información dispersa | ✓ | ✓ | | | |
| P2 - Descontrol inventario | ✓ | ✓ | ✓ | | |
| P3 - Disponibilidad real | ✓ | ✓ | ✓ | ✓ | |
| P4 - Reservas manuales | | ✓ | | ✓ | |
| P5 - Ventas sin integrar | ✓ | ✓ | ✓ | | |
| P6 - Pagos sin control | ✓ | ✓ | ✓ | | |
| P7 - Proveedores | ✓ | | | | ✓ |
| P8 - Trazabilidad | ✓ | ✓ | | | |
| P9 - Catálogo | ✓ | | | | |
| P10 - Reportes | ✓ | ✓ | | | |
| P11 - Seguridad | ✓ | | | | |
| P12 - Experiencia | | | | ✓ | |

## 5. Estimación Cualitativa

| Problema | Impacto | Frecuencia | Criticidad |
|----------|---------|------------|------------|
| P1 | Alto | Constante | 🔴 Crítico |
| P2 | Alto | Diario | 🔴 Crítico |
| P3 | Alto | Diario | 🔴 Crítico |
| P4 | Medio | Semanal | 🟡 Alto |
| P5 | Alto | Diario | 🔴 Crítico |
| P6 | Medio | Diario | 🟡 Alto |
| P7 | Medio | Semanal | 🟡 Alto |
| P8 | Alto | Diario | 🔴 Crítico |
| P9 | Medio | Semanal | 🟡 Alto |
| P10 | Alto | Semanal | 🔴 Crítico |
| P11 | Alto | Constante | 🔴 Crítico |
| P12 | Medio | Constante | 🟡 Alto |

## 6. Alternativas de Cambio

| Problema | Alternativa |
|----------|-------------|
| P1 | Plataforma centralizada con BD única |
| P2 | Módulo de inventario con actualización automática |
| P3 | Consulta de disponibilidad en tiempo real |
| P4 | Módulo de reservas digital |
| P5 | Gestión unificada de ventas multicanal |
| P6 | Módulo de pagos con pasarela integrada |
| P7 | Gestión de proveedores y órdenes de compra |
| P8 | Registro de movimientos de inventario |
| P9 | Catálogo estructurado por categorías/temporadas |
| P10 | Dashboard + generación de reportes |
| P11 | Autenticación con roles, permisos y bitácora |
| P12 | Vestidor virtual + IA de recomendaciones |

## 7. Conclusión

La principal necesidad de **MenStyle** es una **plataforma tecnológica integrada** que centralice la información y coordine los procesos de las sucursales y canales de venta.

Los 12 problemas están interrelacionados. La solución debe:
- Ser **centralizada** (una sola fuente de verdad)
- Ser **multicanal** (web, móvil, presencial)
- Tener **control de acceso** robusto
- Incorporar **automatización** e **IA** como diferenciadores
