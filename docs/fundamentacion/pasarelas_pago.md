# Fundamentación Teórica: Pasarelas de Pago

## 1. Formas de Pago Online

### 1.1 Tarjetas de Débito

**Funcionamiento:**
- Vinculadas directamente a una cuenta bancaria
- El monto se deduce inmediatamente
- Requiere PIN o firma

**Ventajas:**
- Transacción inmediata
- Fácil seguimiento de gastos
- Sin deuda acumulada

**Desventajas:**
- Limitada por el saldo disponible
- Menos protección contra fraudes

### 1.2 Tarjetas de Crédito

**Funcionamiento:**
- Permiten compras a crédito
- Pago total o mínimo en fecha futura
- Intereses si no se paga el total

**Ventajas:**
- Flexibilidad de pago
- Mayor protección contra fraudes
- Puntos o recompensas

**Desventajas:**
- Intereses
- Posible deuda acumulada

### 1.3 QR (Quick Response)

**Funcionamiento:**
- Usuario escanea código QR con móvil
- El código contiene info de la transacción
- Se procesa el pago

**Ventajas:**
- Rápido y conveniente
- Ideal para pagos móviles
- Bajo costo

**Desventajas:**
- Dependencia de tecnología móvil
- Riesgo de errores de escaneo

### 1.4 Transferencias Bancarias

**Funcionamiento:**
- Transferencia directa entre cuentas
- A través de banca en línea o móvil

**Ventajas:**
- Directo entre cuentas
- Ideal para montos grandes
- Bajo costo

**Desventajas:**
- Puede tardar
- Algunas tienen tarifas

## 2. LIBÉLULA (Pasarela Local - Bolivia)

**¿Qué es?**
LIBÉLULA es una pasarela de pago boliviana que permite procesar pagos en línea de manera segura.

**Funcionalidad:**
- Integración con tiendas en línea
- Soporte para múltiples métodos de pago
- Seguridad para proteger datos
- Herramientas para gestionar transacciones

**Ventajas:**
- Adaptada al mercado boliviano
- Soporte en español
- Integración con bancos locales

**Caso de uso en Bolivia:**
Ideal para negocios bolivianos que quieren cobrar online con tarjetas locales.

**Documentación:** https://www.libelula.com.bo/

## 3. STRIPE (Pasarela Internacional)

**¿Qué es?**
STRIPE es una pasarela de pago internacional conocida por su simplicidad y flexibilidad.

**Beneficios:**
- **Facilidad de integración:** API REST + SDKs para Python, JavaScript, etc.
- **Soporte global:** Múltiples monedas y países
- **Seguridad:** Cumple con PCI DSS
- **Análisis:** Herramientas de reportes financieros

**Modo Sandbox (Pruebas):**
- Modo test con tarjetas de prueba
- No procesa pagos reales
- Ideal para desarrollo y demos

**Tarjetas de prueba:**
| Número | Resultado |
|--------|-----------|
| 4242 4242 4242 4242 | Pago exitoso |
| 4000 0000 0000 0002 | Pago rechazado |
| 4000 0000 0000 9995 | Fondos insuficientes |

**Documentación:** https://stripe.com/docs

## 4. PayPal (Pasarela Internacional)

**¿Qué es?**
PayPal es una de las pasarelas de pago más antiguas y reconocidas a nivel mundial.

**Beneficios:**
- Reconocimiento global
- No requiere ingresar tarjeta en cada compra
- Protección al comprador
- Multi-moneda

**Modo Sandbox:**
- Cuenta de negocio de prueba
- Simula transacciones reales
- Ideal para desarrollo

**Documentación:** https://developer.paypal.com/

## 5. Comparativa

| Característica | LIBÉLULA | Stripe | PayPal |
|----------------|----------|--------|--------|
| **Región** | Bolivia | Global | Global |
| **Moneda** | BOB | Multimoneda | Multimoneda |
| **Comisión** | Variable | 2.9% + $0.30 | 2.9% + $0.30 |
| **Sandbox** | Sí | Sí | Sí |
| **Complejidad** | Media | Baja | Baja |
| **Ideal para** | Negocios BO | Startups | Cualquiera |

## 6. Decisión para MenStyle

**Pasarela elegida: STRIPE (modo sandbox)**

**Razones:**
1. **Fácil integración** con FastAPI
2. **Modo test** sin necesidad de cuenta real
3. **Documentación clara** en español
4. **Cumple con el PDF del examen** (menciona Stripe explícitamente)
5. **Tarjetas de prueba** para demos

**Implementación:**
- Endpoint: `POST /api/pagos/stripe`
- Modo: sandbox (test)
- Moneda: USD
- Metadata: asociación con pedido

## 7. Conclusión

Stripe es la mejor opción para MenStyle por su facilidad de integración, modo sandbox y cumplimiento con el PDF. Alternativamente, LIBÉLULA sería la opción local si el proyecto se comercializa en Bolivia.

---

**Referencias:**
- LIBÉLULA: https://www.libelula.com.bo/
- Stripe: https://stripe.com/docs
- PayPal: https://developer.paypal.com/
- PCI DSS: https://www.pcisecuritystandards.org/
