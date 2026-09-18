# Fundamentación Teórica: Delivery

## 1. ¿Cómo funcionan los Deliveries?

Los servicios de delivery conectan clientes con comercios y repartidores.

### 1.1 Ejemplo: Pedidos Ya / Yaigo / Yummy

**Proceso típico:**

1. **Pedido:** El cliente realiza el pedido en la app
2. **Confirmación:** El comercio confirma y prepara
3. **Asignación:** El sistema asigna un repartidor
4. **Recogida:** El repartidor recoge el pedido
5. **Entrega:** El repartidor entrega al cliente
6. **Pago:** El cliente paga (en línea o efectivo)
7. **Confirmación:** Cliente y comercio confirman recepción

### 1.2 Tipos de Delivery

| Tipo | Descripción | Ejemplo |
|------|-------------|---------|
| **Restaurantes** | Comida preparada | Pedidos Ya, Uber Eats |
| **Supermercados** | Productos de supermercado | Cornershop |
| **Farmacias** | Medicamentos | Farmacias locales |
| **Retail** | Ropa, electrónica | Amazon, Rappi |

## 2. Cálculo de Pagos para Entregas

Los deliveries calculan el costo según **5 factores principales**:

### 2.1 Distancia

**Fórmula típica:**

costo_distancia = tarifa_base + (km_recorridos × tarifa_por_km)
text


**Ejemplo:**
- Tarifa base: $1.00
- Por km: $0.50
- Distancia: 5 km → Costo: $1.00 + (5 × $0.50) = $3.50

### 2.2 Peso

**Fórmula típica:**

costo_peso = peso_total × tarifa_por_kg
text


**Ejemplo:**
- Por kg: $0.25
- Peso: 10 kg → Costo adicional: $2.50

### 2.3 Tamaño

Paquetes grandes requieren vehículos especiales:
- Motos: paquetes pequeños
- Autos: paquetes medianos
- Camionetas: paquetes grandes

**Costo adicional por tamaño:**
| Tamaño | Costo extra |
|--------|-------------|
| Pequeño | $0 |
| Mediano | $1.00 |
| Grande | $3.00 |

### 2.4 Urgencia

**Tarifas diferenciadas:**
- **Estándar:** 45-60 min → Precio base
- **Express:** 20-30 min → +50% del precio
- **Programado:** Fecha/hora específica → Variable

### 2.5 Frecuencia

**Descuentos por fidelidad:**
- Cliente frecuente: -10%
- Suscripción: envíos gratis
- Promociones: 2x1 en envíos

## 3. Ejemplo Completo de Cálculo

**Pedido:**
- Distancia: 5 km
- Peso: 2 kg
- Tamaño: Mediano
- Urgencia: Express
- Cliente: Frecuente (10% descuento)

**Cálculo:**

Tarifa base: $1.00
Distancia (5 × $0.50): $2.50
Peso (2 × $0.25): $0.50
Tamaño mediano: $1.00
Subtotal: $5.00
Urgencia (+50%): $2.50
Subtotal: $7.50
Descuento (-10%): -$0.75
TOTAL: $6.75
text


## 4. Aplicación a MenStyle

**¿MenStyle incluye delivery?**
- ❌ **NO en el MVP** (el PDF menciona delivery pero no está en RF obligatorios)
- 🟡 **Podría incluirse como mejora futura**

**Si se implementara:**
- Cálculo según distancia desde sucursal a cliente
- Peso del paquete (ropa es ligero)
- Frecuencia de compra del cliente
- Integración con servicio externo (Yaigo, Yummy)

**Estado actual:** Fuera del alcance del MVP.

## 5. Conclusión

Los deliveries son un componente complejo que involucra logística, tarifas dinámicas y coordinación. Para el MVP de MenStyle se prioriza la compra/reserva con recogida en tienda. El delivery se deja como **funcionalidad futura** (mencionada en el PDF pero no en los RF).

---

**Referencias:**
- Pedidos Ya: https://www.pedidosya.com
- Yaigo: https://yaigo.com
- Yummy: https://yummy.com.bo
- Rappi: https://www.rappi.com