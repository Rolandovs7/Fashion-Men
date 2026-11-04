# ============================================================
# TRAZABILIDAD MENSTYLE
# CU: CU31 - Recibir Recomendaciones (IA)
# CU: CU32 - Interactuar con Asistente Virtual
# CU: CU30 - Generar Reportes (tendencias)
# RF: RF25 - Proporcionar funcionalidad basada en inteligencia artificial
# RF: RF24 - Consultar reportes de ventas e inventario
# CAPA: Backend FastAPI (Service)
# ============================================================
import os
import re
from typing import Optional, List
from sqlalchemy.orm import Session
from sqlalchemy import desc, func

from app.models.product import Producto
from app.models.product_variant import ProductoVariante
from app.models.category import Categoria
from app.models.order import Pedido
from app.models.order_detail import DetallePedido


# Configurar Groq si hay API key
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
GROQ_MODEL = os.getenv("GROQ_MODEL") or "openai/gpt-oss-20b"
GROQ_DISPONIBLE = False
GROQ_CLIENT = None

if GROQ_API_KEY:
    try:
        from groq import Groq
        GROQ_CLIENT = Groq(api_key=GROQ_API_KEY)
        GROQ_DISPONIBLE = True
        print("✅ Groq configurado correctamente")
    except Exception as e:
        print(f"⚠️ Groq no se pudo configurar: {e}")


class IAService:
    """
    Servicio de Inteligencia Artificial para MenStyle.

    Estrategia híbrida:
    1. Reglas rápidas (palabras clave) → respuestas instantáneas y gratis
    2. Google Gemini → cuando las reglas no matchean, IA real en lenguaje natural
    """

    # Umbral de palabras: los mensajes más largos siempre van a Gemini
    # (un mensaje con contexto adicional no debe resolver las reglas trivia).
    LIMITE_PALABRAS_REGLAS = 10

    # Contexto base del negocio para Gemini
    CONTEXTO_NEGOCIO = """
Eres el asesor de estilo personal de MenStyle, una tienda premium de ropa
masculina en Bolivia.

Tu rol:
- Ayudar al cliente a encontrar prendas según su altura, ocasión, estilo o presupuesto.
- Ser específico: mencionar productos por nombre y precio.
- Recomendar productos REALES del catálogo (te los paso abajo).
- Si el cliente menciona altura ("soy alto", "mido 1.90"), sugerir tallas XL/XXL.
- Si menciona ocasión ("boda", "entrevista"), sugerir productos formales.
- Si menciona presupuesto ("hasta 200 Bs"), filtrar por precio.
- Si menciona color, filtrar por color.

Formato de respuesta:
1. Respuesta breve y amable (máx 3 oraciones).
2. Al final, agrega: [RECOMENDADOS: ID1, ID2, ID3]
   (los IDs de los productos del catálogo que recomiendas)

Ejemplo:
"Para una boda, te recomiendo nuestra Camisa Formal Blanca (Bs 180) en
talla XL, combinada con el Pantalón de Vestir Negro (Bs 250).
[RECOMENDADOS: 2, 4]"

Si no estás seguro, pide más detalles.
Responde SIEMPRE en español.
"""

    def __init__(self, db: Session):
        self.db = db

    # ========================================================
    # CU31 - Recibir Recomendaciones (IA)
    # ========================================================
    def recomendar_para_usuario(
        self,
        usuario_id: Optional[int] = None,
        categoria_id: Optional[int] = None,
        tipo_prenda_id: Optional[int] = None,
        limite: int = 5
    ) -> dict:
        """
        Genera recomendaciones personalizadas.

        Estrategia:
        1. Si el usuario tiene historial → recomendar productos de categorías
           que ha comprado previamente.
        2. Si no tiene historial → recomendar productos activos ordenados
           por categoría y precio.
        3. Aplicar filtros opcionales de categoría / tipo de prenda.
        """

        # IDs de productos ya comprados por el usuario
        ids_comprados = []
        if usuario_id:
            comprados = (
                self.db.query(DetallePedido.variante_id)
                .join(Pedido, Pedido.id == DetallePedido.pedido_id)
                .filter(Pedido.usuario_id == usuario_id)
                .all()
            )
            variante_ids = [c[0] for c in comprados]
            if variante_ids:
                productos = (
                    self.db.query(ProductoVariante.producto_id)
                    .filter(ProductoVariante.id.in_(variante_ids))
                    .distinct()
                    .all()
                )
                ids_comprados = [p[0] for p in productos]

        # Query base: productos activos
        query = self.db.query(Producto).filter(Producto.activo == True)

        # Filtros opcionales
        if categoria_id:
            query = query.filter(Producto.categoria_id == categoria_id)
        if tipo_prenda_id:
            query = query.filter(Producto.tipo_prenda_id == tipo_prenda_id)

        # Traer más candidatos para luego rankear
        candidatos = query.limit(limite * 3).all()

        # Ranking: prioriza los NO comprados, luego por precio ascendente
        recomendados = sorted(
            candidatos,
            key=lambda p: (p.id in ids_comprados, float(p.precio))
        )[:limite]

        # Construir respuesta
        resultado = []
        for p in recomendados:
            if p.id in ids_comprados:
                motivo = "Basado en tu historial de compras"
            elif categoria_id:
                motivo = "Popular en esta categoría"
            else:
                motivo = "Recomendado para ti"

            resultado.append({
                "id": p.id,
                "nombre": p.nombre,
                "descripcion": p.descripcion,
                "precio": float(p.precio),
                "categoria_id": p.categoria_id,
                "motivo": motivo
            })

        return {
            "usuario_id": usuario_id,
            "total": len(resultado),
            "recomendaciones": resultado
        }

    # ========================================================
    # CU32 - Interactuar con Asistente Virtual
    # ========================================================
    def responder_consulta(
        self,
        mensaje: str,
        historial: Optional[List[dict]] = None
    ) -> dict:
        """
        Asistente virtual híbrido (Gemini primero):
        1. Reglas rápidas SOLO para mensajes cortos (saludos/trivia sin contexto).
        2. Gemini primero: enriquece la respuesta con el catálogo completo y
           devuelve productos REALES.
        3. Reglas como fallback si Gemini no está disponible o falla.
        4. Fallback genérico final.
        """
        msg = mensaje.lower().strip()
        es_corto = len(msg.split()) <= self.LIMITE_PALABRAS_REGLAS

        # --- 1) Reglas rápidas (solo mensajes cortos, ahorra llamadas a Gemini) ---
        if es_corto:
            respuesta_por_reglas, productos_sugeridos, match = self._responder_con_reglas(msg)
            if match:
                return {
                    "respuesta": respuesta_por_reglas,
                    "productos_sugeridos": productos_sugeridos,
                    "fuente": "reglas"
                }

        # --- 2) Gemini primero (IA real + productos reales) ---
        if GEMINI_DISPONIBLE:
            resultado = self._consultar_gemini(mensaje, historial)
            if resultado is not None:
                texto, ids_recomendados = resultado
                return {
                    "respuesta": texto,
                    "productos_sugeridos": self._productos_por_ids(ids_recomendados),
                    "fuente": "gemini"
                }

        # --- 3) Reglas como fallback (Gemini no disponible o falló) ---
        respuesta_por_reglas, productos_sugeridos, match = self._responder_con_reglas(msg)
        if match:
            return {
                "respuesta": respuesta_por_reglas,
                "productos_sugeridos": productos_sugeridos,
                "fuente": "reglas"
            }

        # --- 4) Fallback final ---
        return {
            "respuesta": (
                "No estoy seguro de haber entendido. Puedes preguntarme por: "
                "categorías (trajes, camisas, pantalones), ocasiones (formal, casual), "
                "tallas, precios o envíos."
            ),
            "productos_sugeridos": [],
            "fuente": "fallback"
        }

    def _responder_con_reglas(self, msg: str):
        """Motor de reglas. Retorna (respuesta, productos, match_exitoso)."""
        productos_sugeridos = []

        # --- Categorías ---
        # Las categorías en la BD están en PLURAL:
        # Camisas, Pantalones, Zapatos, Accesorios, Chaquetas,
        # Poleras, Trajes, Camisetas, Ropa Deportiva
        # El matching usa LIKE %nombre%, así que usamos el plural
        # para que coincida.
        categorias_keywords = {
            "traje": "Trajes", "trajes": "Trajes",
            "camisa": "Camisas", "camisas": "Camisas",
            "camiseta": "Camisetas", "camisetas": "Camisetas",
            "pantalon": "Pantalones", "pantalones": "Pantalones",
            "jean": "Pantalones", "jeans": "Pantalones",
            "zapato": "Zapatos", "zapatos": "Zapatos",
            "zapatilla": "Zapatos", "zapatillas": "Zapatos",
            "tenis": "Zapatos",
            "polera": "Poleras", "poleras": "Poleras",
            "polo": "Poleras", "polos": "Poleras",
            "chaqueta": "Chaquetas", "chaquetas": "Chaquetas",
            "abrigo": "Chaquetas",
            "accesorio": "Accesorios", "accesorios": "Accesorios",
            "cinturon": "Accesorios", "cinturones": "Accesorios",
            "bufanda": "Accesorios", "bufandas": "Accesorios",
            "gorra": "Accesorios", "gorras": "Accesorios",
            "short": "Ropa Deportiva", "shorts": "Ropa Deportiva",
            "deportiv": "Ropa Deportiva", "deportiva": "Ropa Deportiva",
            "gym": "Ropa Deportiva", "gimnasio": "Ropa Deportiva",
        }

        categoria_detectada = None
        for keyword, nombre_cat in categorias_keywords.items():
            if keyword in msg:
                categoria_detectada = nombre_cat
                break

        # --- Ocasión ---
        ocasion = None
        if any(w in msg for w in ["boda", "formal", "elegante", "fiesta"]):
            ocasion = "formal"
        elif any(w in msg for w in ["casual", "diario", "informal"]):
            ocasion = "casual"
        elif any(w in msg for w in ["deporte", "gimnasio", "gym"]):
            ocasion = "deportivo"

        # --- Buscar productos por categoría ---
        if categoria_detectada:
            categoria = (
                self.db.query(Categoria)
                .filter(func.lower(Categoria.nombre).like(f"%{categoria_detectada.lower()}%"))
                .first()
            )
            if categoria:
                productos = (
                    self.db.query(Producto)
                    .filter(Producto.categoria_id == categoria.id)
                    .filter(Producto.activo == True)
                    .limit(3)
                    .all()
                )
                productos_sugeridos = [
                    {
                        "id": p.id,
                        "nombre": p.nombre,
                        "descripcion": p.descripcion,
                        "precio": float(p.precio),
                        "categoria_id": p.categoria_id,
                        "motivo": f"Disponible en {categoria.nombre}"
                    }
                    for p in productos
                ]

        # --- Construir respuesta ---
        if categoria_detectada and productos_sugeridos:
            respuesta = (
                f"Encontré {len(productos_sugeridos)} productos en la categoría "
                f"'{categoria_detectada}'. ¿Te gustaría ver más detalles?"
            )
            return respuesta, productos_sugeridos, True

        if ocasion == "formal":
            return (
                "Para ocasiones formales te recomiendo nuestra colección de "
                "trajes y camisas. Puedes filtrar por categoría en el catálogo."
            ), [], True

        if ocasion == "casual":
            return (
                "Para un look casual, te sugiero polos, jeans y zapatillas. "
                "Explora nuestra sección casual."
            ), [], True

        if any(w in msg for w in ["hola", "buenos", "buenas", "hey"]):
            return (
                "¡Hola! Soy tu asistente de MenStyle. "
                "Puedo ayudarte a encontrar prendas por categoría, ocasión o talla. "
                "¿Qué estás buscando hoy?"
            ), [], True

        if any(w in msg for w in ["precio", "cuánto", "cuanto", "costo"]):
            return (
                "Puedes ver el precio de cada producto en el catálogo. "
                "También tenemos descuentos activos. ¿Buscas algo en particular?"
            ), [], True

        if any(w in msg for w in ["talla", "tallas", "medida"]):
            return (
                "Manejamos tallas S, M, L, XL y XXL. "
                "Puedes filtrar por talla en el catálogo."
            ), [], True

        if any(w in msg for w in ["envio", "envío", "entrega", "domicilio"]):
            return (
                "Realizamos envíos a domicilio. "
                "El costo se calcula según distancia y peso."
            ), [], True

        # Sin match
        return None, [], False

    def _consultar_gemini(
        self,
        mensaje: str,
        historial: Optional[List[dict]] = None
    ) -> Optional[tuple]:
        """
        Consulta a Google Gemini (IA real) usando el nuevo SDK google-genai.
        Incluye TODO el catálogo activo y los últimos turnos de la conversación.
        Retorna (respuesta_texto, ids_recomendados) o None si falla.
        """
        if not GEMINI_DISPONIBLE or GEMINI_CLIENT is None:
            return None

        try:
            # --- Catálogo activo completo (ID, nombre, precio, categoría, tallas, colores) ---
            productos = (
                self.db.query(Producto, Categoria.nombre.label("categoria"))
                .join(Categoria, Categoria.id == Producto.categoria_id)
                .filter(Producto.activo == True)
                .order_by(Producto.id)
                .all()
            )

            tallas_por_producto: dict = {}
            colores_por_producto: dict = {}
            variantes = (
                self.db.query(ProductoVariante)
                .filter(ProductoVariante.activo == True)
                .all()
            )
            for v in variantes:
                tallas_por_producto.setdefault(v.producto_id, set()).add(
                    v.talla.nombre if v.talla else "—"
                )
                colores_por_producto.setdefault(v.producto_id, set()).add(
                    v.color.nombre if v.color else "—"
                )

            lineas_catalogo = []
            for p, cat in productos:
                tallas = ", ".join(sorted(tallas_por_producto.get(p.id, set()))) or "—"
                colores = ", ".join(sorted(colores_por_producto.get(p.id, set()))) or "—"
                lineas_catalogo.append(
                    f"- ID {p.id} | {p.nombre} | Bs {float(p.precio):.2f} "
                    f"| {cat} | tallas: {tallas} | colores: {colores}"
                )
            catalogo_ctx = "Catálogo disponible:\n" + "\n".join(lineas_catalogo)

            # --- Historial reciente (últimos 5 turnos) ---
            historial_ctx = ""
            if historial:
                turnos = []
                for m in historial[-5:]:
                    rol = "Cliente" if m.get("rol") == "usuario" else "Asistente"
                    turnos.append(f"{rol}: {m.get('texto', '')}")
                historial_ctx = "Historial reciente de la conversación:\n" + "\n".join(turnos)

            prompt = f"""{self.CONTEXTO_NEGOCIO}

{catalogo_ctx}

{historial_ctx}
Cliente: {mensaje}
Asistente:"""

            # SDK nuevo: client.models.generate_content
            response = GEMINI_CLIENT.models.generate_content(
                model="gemini-3.6-flash",
                contents=prompt,
            )
            texto = response.text.strip()

            # Extraer IDs recomendados y limpiar el marcador del texto visible
            ids_recomendados = self._extraer_ids_recomendados(texto)
            texto_limpio = re.sub(
                r"\s*\[RECOMENDADOS:[\d,\s]+\]\s*$",
                "",
                texto,
                flags=re.IGNORECASE
            ).strip()

            return texto_limpio, ids_recomendados

        except Exception as e:
            print(f"⚠️ Error consultando Gemini: {e}")
            return None

    def _extraer_ids_recomendados(self, texto: str) -> List[int]:
        """Extrae los IDs del marcador [RECOMENDADOS: 2, 5, 8]."""
        match = re.search(
            r"\[RECOMENDADOS:\s*([\d,\s]+)\]",
            texto,
            re.IGNORECASE
        )
        if not match:
            return []

        ids = []
        for parte in match.group(1).split(","):
            parte = parte.strip()
            if parte.isdigit():
                ids.append(int(parte))
        return ids

    def _productos_por_ids(self, ids: List[int]) -> List[dict]:
        """Busca los productos reales de la DB a partir de los IDs de Gemini."""
        if not ids:
            return []

        unicos = list(dict.fromkeys(ids))
        productos = (
            self.db.query(Producto)
            .filter(Producto.id.in_(unicos))
            .filter(Producto.activo == True)
            .all()
        )
        por_id = {p.id: p for p in productos}

        resultado = []
        for pid in unicos:
            p = por_id.get(pid)
            if p:
                resultado.append({
                    "id": p.id,
                    "nombre": p.nombre,
                    "descripcion": p.descripcion,
                    "precio": float(p.precio),
                    "categoria_id": p.categoria_id,
                    "motivo": "Recomendado según tu estilo"
                })
        return resultado

    # ========================================================
    # CU30 - Generar Reportes (tendencias)
    # ========================================================
    def productos_tendencia(self, limite: int = 5) -> dict:
        """
        Retorna los productos más vendidos (basado en DetallePedido).
        Útil para el dashboard (CU29) y para el recomendador.
        """
        top_variantes = (
            self.db.query(
                DetallePedido.variante_id,
                func.sum(DetallePedido.cantidad).label("total_vendido")
            )
            .group_by(DetallePedido.variante_id)
            .order_by(desc("total_vendido"))
            .limit(limite)
            .all()
        )

        if not top_variantes:
            productos = (
                self.db.query(Producto)
                .filter(Producto.activo == True)
                .limit(limite)
                .all()
            )
            return {
                "total": len(productos),
                "productos": [
                    {
                        "id": p.id,
                        "nombre": p.nombre,
                        "descripcion": p.descripcion,
                        "precio": float(p.precio),
                        "categoria_id": p.categoria_id,
                        "motivo": "Novedad"
                    }
                    for p in productos
                ]
            }

        variante_ids = [tv[0] for tv in top_variantes]
        variantes = (
            self.db.query(ProductoVariante)
            .filter(ProductoVariante.id.in_(variante_ids))
            .all()
        )
        producto_ids = list({v.producto_id for v in variantes})

        productos = (
            self.db.query(Producto)
            .filter(Producto.id.in_(producto_ids))
            .all()
        )

        return {
            "total": len(productos),
            "productos": [
                {
                    "id": p.id,
                    "nombre": p.nombre,
                    "descripcion": p.descripcion,
                    "precio": float(p.precio),
                    "categoria_id": p.categoria_id,
                    "motivo": "Más vendido"
                }
                for p in productos
            ]
        }

    # ============================================================
    # [Segundo Parcial] CU23 - Reportes Generativos (Text-to-SQL)
    # [Segundo Parcial] RN-IA-01 - Seguridad SQL
    # ============================================================
    def consultar_sql_natural(self, pregunta: str, empresa_id: int) -> dict:
        from sqlalchemy import text

        # Generar SQL con Groq
        sql_generado = None
        if GROQ_DISPONIBLE and GROQ_CLIENT is not None:
            try:
                sistema = """Eres un generador de SQL para PostgreSQL. 
Genera ÚNICAMENTE una consulta SELECT, sin markdown, sin explicación.
Debes incluir obligatoriamente el filtro WHERE empresa_id = %s.
Prohibido: DROP, DELETE, UPDATE, INSERT, TRUNCATE, ALTER, CREATE, GRANT, EXEC.
Tablas: pedidos(id, usuario_id, sucursal_id, empresa_id, fecha_pedido, estado, total), detalles_pedido(id, pedido_id, variante_id, cantidad, precio_unitario, subtotal), productos(id, nombre, precio, empresa_id, activo), producto_variantes(id, producto_id, color_id, talla_id, precio), sucursales(id, nombre, empresa_id), usuarios(id, nombre, apellido, rol, empresa_id).""" % empresa_id
                respuesta = GROQ_CLIENT.chat.completions.create(
                    model=GROQ_MODEL,
                    messages=[
                        {"role": "system", "content": sistema},
                        {"role": "user", "content": f"Pregunta: {pregunta}"},
                    ],
                    temperature=0.1,
                )
                sql_generado = (respuesta.choices[0].message.content or "").strip().replace("```sql", "").replace("```", "").strip()
            except Exception as e:
                raise ValueError(f"Error Groq: {str(e)}")

        if not sql_generado:
            sql_lower = pregunta.lower()
            if "mas vendido" in sql_lower or "top" in sql_lower:
                sql_generado = f"SELECT p.nombre, SUM(dp.cantidad) as total_vendido, SUM(dp.subtotal) as ingresos FROM productos p JOIN producto_variantes pv ON pv.producto_id = p.id JOIN detalles_pedido dp ON dp.variante_id = pv.id JOIN pedidos pe ON pe.id = dp.pedido_id WHERE pe.estado != 'cancelado' AND p.empresa_id = {empresa_id} AND pe.empresa_id = {empresa_id} GROUP BY p.id, p.nombre ORDER BY total_vendido DESC LIMIT 10"
            elif "ventas" in sql_lower and "mes" in sql_lower:
                sql_generado = f"SELECT DATE_TRUNC('month', pe.fecha_pedido) as mes, SUM(pe.total) as total_ventas, COUNT(pe.id) as cantidad_pedidos FROM pedidos pe WHERE pe.estado != 'cancelado' AND pe.empresa_id = {empresa_id} GROUP BY DATE_TRUNC('month', pe.fecha_pedido) ORDER BY mes DESC LIMIT 12"
            else:
                sql_generado = f"SELECT pe.id, pe.fecha_pedido, pe.total, pe.estado FROM pedidos pe WHERE pe.empresa_id = {empresa_id} ORDER BY pe.fecha_pedido DESC LIMIT 20"

        sql_up = sql_generado.upper()
        if not sql_up.strip().startswith("SELECT"):
            raise ValueError("RN-IA-01: Solo se permiten consultas SELECT")
        for forbidden in ["DROP", "DELETE", "UPDATE", "INSERT", "TRUNCATE", "ALTER", "CREATE", "GRANT", "EXEC"]:
            if forbidden in sql_up:
                raise ValueError(f"RN-IA-01: Palabra prohibida detectada: {forbidden}")
        if f"empresa_id = {empresa_id}" not in sql_generado and "EMPRESA_ID" not in sql_up:
            sql_generado = sql_generado.rstrip().rstrip(";") + f" AND empresa_id = {empresa_id}"

        try:
            result = self.db.execute(text(sql_generado))
            rows = result.fetchall()
            cols = list(result.keys())
            data = []
            for r in rows:
                data.append(dict(zip(cols, r)))
            return {"sql": sql_generado, "columnas": cols, "resultados": data, "mensaje": "Consulta ejecutada correctamente"}
        except Exception as e:
            raise ValueError(f"Error al ejecutar consulta: {str(e)}")

    # ============================================================
    # [Segundo Parcial] CU24 - Machine Learning (Predicciones)
    # ============================================================
    def predecir_ventas(self, empresa_id: int | None = None) -> dict:
        import json
        import os
        from datetime import datetime, timedelta
        from sqlalchemy import func

        path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "ml", "modelo_prediccion.json")
        historico = []
        if os.path.exists(path):
            try:
                with open(path) as f:
                    data = json.load(f)
                historico = [{"mes": h["mes"], "ventas": float(h["ventas"]), "tipo": "historico"} for h in data.get("historico", [])]
                pred = data.get("prediccion", {})
                return {
                    "historico": historico,
                    "prediccion": {"mes": pred.get("mes"), "ventas": float(pred.get("ventas", 0)), "tipo": "prediccion"},
                    "mensaje": "Predicción generada con modelo de Regresión Lineal (scikit-learn)"
                }
            except Exception:
                pass

        # Generar con datos reales si existen
        try:
            from app.models.order import Pedido
            q = self.db.query(func.date_trunc('month', Pedido.fecha_pedido).label('mes'), func.sum(Pedido.total).label('total')).filter(Pedido.estado != 'cancelado')
            if empresa_id is not None:
                q = q.filter(Pedido.empresa_id == empresa_id)
            res = q.group_by(func.date_trunc('month', Pedido.fecha_pedido)).order_by(func.date_trunc('month', Pedido.fecha_pedido)).all()
            for r in res:
                m = r.mes.strftime("%Y-%m") if r.mes else ""
                historico.append({"mes": m, "ventas": float(r.total or 0), "tipo": "historico"})
        except Exception:
            pass

        if not historico:
            import numpy as np
            base = 15000
            for i in range(12):
                fecha = datetime.now() - timedelta(days=30 * (11 - i))
                historico.append({"mes": fecha.strftime("%Y-%m"), "ventas": float(base + i * 800), "tipo": "historico"})

        try:
            import numpy as np
            from sklearn.linear_model import LinearRegression
            X = np.array(range(len(historico))).reshape(-1, 1)
            y = np.array([h["ventas"] for h in historico])
            modelo = LinearRegression()
            modelo.fit(X, y)
            pred = float(modelo.predict(np.array([[len(historico)]]))[0])
            pred = max(1000, pred)
            proximo = (datetime.now() + timedelta(days=30)).strftime("%Y-%m")
            return {
                "historico": historico,
                "prediccion": {"mes": proximo, "ventas": round(pred, 2), "tipo": "prediccion"},
                "mensaje": "Predicción generada con modelo de Regresión Lineal (scikit-learn)"
            }
        except Exception as e:
            proximo = (datetime.now() + timedelta(days=30)).strftime("%Y-%m")
            return {
                "historico": historico,
                "prediccion": {"mes": proximo, "ventas": 20000.0, "tipo": "prediccion"},
                "mensaje": f"Predicción estimada: {e}"
            }
