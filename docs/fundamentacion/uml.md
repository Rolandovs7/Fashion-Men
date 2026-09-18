# Fundamentación Teórica: UML 2.5+

## 1. ¿Qué es UML?

El **Lenguaje Unificado de Modelado (UML)** es un lenguaje visual estándar para especificar, visualizar, construir y documentar sistemas de software.

## 2. Características de UML 2.5+

### 2.1 Estandarización

- Estándar respaldado por **OMG** (Object Management Group)
- Notación y reglas comunes
- Reconocido internacionalmente

### 2.2 Modelado Visual

- Diagramas gráficos
- Facilita comunicación entre equipo y stakeholders
- Independiente del lenguaje de programación

### 2.3 Versatilidad

- Aplicable a software, procesos de negocio, sistemas en tiempo real
- Múltiples tipos de diagramas
- Adaptable a diferentes necesidades

### 2.4 Abstracción

- Diferentes niveles de detalle
- Modela estructura (clases, objetos) y comportamiento (secuencia, estados)

### 2.5 Reutilización

- Fomenta reutilización de componentes
- Documentación de patrones de diseño
- Ayuda a comprender componentes existentes

## 3. Diagramas UML 2.5+ Usados en MenStyle

### 3.1 Diagramas de Estructura

| Diagrama | Propósito | Aplicado en |
|----------|-----------|-------------|
| **Casos de Uso** | Funcionalidad desde la perspectiva del usuario | `04_captura_requisitos/` |
| **Clases** | Estructura estática del sistema | `05_analisis/`, `06_diseno/` |
| **Componentes** | Módulos del sistema | `07_implementacion/` |
| **Despliegue** | Distribución física | `06_diseno/` |
| **Paquetes** | Agrupación de elementos | `05_analisis/` |

### 3.2 Diagramas de Comportamiento

| Diagrama | Propósito | Aplicado en |
|----------|-----------|-------------|
| **Secuencia** | Interacción temporal entre objetos | `06_diseno/` |
| **Comunicación** | Interacción entre objetos | `05_analisis/` |
| **Actividad** | Flujo de procesos | `03_modelo_negocio/` |
| **Estado** | Ciclo de vida de objetos | `06_diseno/` |
| **Tiempo** | Cambios en el tiempo | `06_diseno/` |

## 4. Notación UML 2.5+

### 4.1 Estereotipos

- `<<include>>`: un caso de uso incluye otro obligatoriamente
- `<<extend>>`: un caso de uso extiende otro opcionalmente
- `<<external>>`: actor o sistema externo
- `<<abstract>>`: clase abstracta

### 4.2 Multiplicidades

| Notación | Significado |
|----------|-------------|
| `1` | Exactamente uno |
| `0..1` | Cero o uno |
| `*` | Cero o muchos |
| `1..*` | Uno o muchos |
| `n..m` | Entre n y m |

### 4.3 Relaciones

| Relación | Notación | Uso |
|----------|----------|-----|
| Asociación | Línea sólida | Relación entre clases |
| Herencia | Flecha con triángulo hueco | Generalización |
| Composición | Rombo relleno | Parte-todo fuerte |
| Agregación | Rombo hueco | Parte-todo débil |
| Dependencia | Flecha discontinua | Uso temporal |

## 5. Herramientas Utilizadas

| Herramienta | Uso |
|-------------|-----|
| **PlantUML** | Diagramas como código (texto `.puml`) |
| **Draw.io** | Diagramas complementarios |
| **Enterprise Architect** | (opcional, para algunos diagramas) |
| **StarUML** | Modelado UML |

**Ventaja de PlantUML:**
- Los diagramas son **texto versionable** con Git
- Fácil de mantener y actualizar
- Compatible con VS Code

## 6. Aplicación a MenStyle

| Diagrama | Cantidad | Ubicación |
|----------|----------|-----------|
| Casos de Uso | 5+ | `04_captura_requisitos/` |
| Actividades | 2 | `03_modelo_negocio/` |
| Clases | 2 (análisis + diseño) | `05_analisis/`, `06_diseno/` |
| Comunicación | 1+ | `05_analisis/` |
| Paquetes | 2 | `05_analisis/` |
| Secuencia | 2+ | `06_diseno/` |
| Estados | 1 | `06_diseno/` |
| Tiempo | 1 | `06_diseno/` |
| Navegación | 1 | `06_diseno/` |
| Red | 1 | `06_diseno/` |
| Componentes | 2+ | `07_implementacion/` |
| Despliegue | 1 | `06_diseno/` |
| **TOTAL** | **20+ diagramas** | |

## 7. Conclusión

UML 2.5+ proporcionó el **lenguaje común** para modelar MenStyle en todas las fases del PUDS. Los 20+ diagramas documentan desde los requisitos (casos de uso) hasta la implementación (componentes), facilitando la comunicación y validación del diseño.

---

**Referencias:**
- OMG UML: https://www.omg.org/spec/UML/
- UML Diagrams: https://www.uml-diagrams.org/
- PlantUML: https://plantuml.com/
