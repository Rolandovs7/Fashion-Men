# Fundamentación Teórica: PUDS

## 1. ¿Qué es el PUDS?

El **Proceso Unificado de Desarrollo de Software (PUDS)** es un marco de desarrollo iterativo e incremental basado en componentes, con énfasis en arquitectura y gestión de riesgos.

## 2. Características Principales

### 2.1 Enfoque Iterativo e Incremental

El proyecto se divide en **mini-proyectos (iteraciones)**. Cada iteración entrega un **incremento funcional**.

**Aplicado a MenStyle:**
- **Ciclo #1:** Autenticación y usuarios
- **Ciclo #2:** Catálogo, inventario, proveedores
- **Ciclo #3:** Ventas, pagos, reservas
- **Ciclo #4:** RA, reportes, IA

### 2.2 Enfoque en la Arquitectura

Se define una arquitectura sólida desde el inicio.

**Aplicado a MenStyle:**
- Arquitectura de capas: Presentación → API → Lógica → Datos
- Stack: Angular + FastAPI + Flutter + PostgreSQL
- Diseño modular por paquetes

### 2.3 Roles Definidos

Cada miembro del equipo tiene responsabilidades claras:
- **Analistas:** Identifican casos de uso
- **Diseñadores:** Crean la arquitectura
- **Programadores:** Implementan componentes
- **Testers:** Verifican funcionalidad

**Aplicado a MenStyle:**
| Rol | Responsable |
|-----|-------------|
| Analista | Rolando Velasco |
| Diseñador | Ambos |
| Programador Backend | Rolando Velasco |
| Programador Frontend | Jimena Jahuira |
| Programador Móvil | Ambos |
| Tester | Ambos |

### 2.4 Gestión de Riesgos

Se identifican y mitigan riesgos temprano.

**Riesgos de MenStyle:**
| Riesgo | Mitigación |
|--------|-----------|
| Integración con Gemini | Plan B: chatbot por reglas |
| RA compleja | Empezar con prototipo básico |
| Tiempo limitado (4 semanas) | Priorizar MVP |
| Despliegue en nube | Docker + Render |

### 2.5 Documentación y Modelado

Uso de **UML 2.5+** para modelos visuales.

**Aplicado a MenStyle:**
- Casos de uso
- Diagramas de clases
- Diagramas de secuencia
- Diagramas de componentes
- Diagramas de despliegue

## 3. Fases del PUDS

### 3.1 Incepción (10%)
- Definir visión y alcance
- Identificar actores y casos de uso principales
- Análisis de riesgos inicial

**Aplicado:** `docs/01_perfil/` + `docs/02_marco_teorico/`

### 3.2 Elaboración (30%)
- Refinar requisitos
- Diseñar arquitectura
- Mitigar riesgos críticos

**Aplicado:** `docs/04_captura_requisitos/` + `docs/05_analisis/`

### 3.3 Construcción (50%)
- Codificar componentes
- Implementar casos de uso
- Pruebas unitarias

**Aplicado:** Backend + Frontend + Mobile + `docs/06_diseno/`

### 3.4 Transición (10%)
- Pruebas de aceptación
- Despliegue
- Capacitación

**Aplicado:** `docs/08_pruebas/` + despliegue en Render

## 4. Flujos de Trabajo

| Flujo | Actividad | Aplicado en |
|-------|-----------|-------------|
| **Captura de Requisitos** | Identificar CU | `docs/04_captura_requisitos/` |
| **Análisis** | Modelo conceptual | `docs/05_analisis/` |
| **Diseño** | Modelo físico | `docs/06_diseno/` |
| **Implementación** | Código | `backend/`, `frontend/`, `mobile/` |
| **Pruebas** | Verificación | `docs/08_pruebas/` |

## 5. Aplicación a MenStyle

| Elemento | Aplicación |
|----------|-----------|
| Iteraciones | 4 ciclos de vida |
| Incrementos | Cada ciclo entrega funcionalidad |
| Arquitectura | Capas: Presentación → API → Lógica → Datos |
| Roles | Definidos por estudiante |
| Riesgos | Mitigados por priorización |
| UML | 20+ diagramas |
| Duración | 4 semanas (MVP) |

## 6. Conclusión

El PUDS guió el desarrollo de MenStyle de forma **estructurada, iterativa y centrada en calidad**. Cada fase y flujo de trabajo se documentó con modelos UML 2.5+, cumpliendo con los requisitos del examen.

---

**Referencias:**
- Jacobson, I., Booch, G., Rumbaugh, J. (1999). *The Unified Software Development Process*. Addison-Wesley.
- Kruchten, P. (2003). *The Rational Unified Process: An Introduction*. Addison-Wesley.
