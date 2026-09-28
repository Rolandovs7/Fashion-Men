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

# --- Google Gemini (IA real) ---
from google import genai
from google.genai import types

from app.models.product import Producto
from app.models.product_variant import ProductoVariante
from app.models.category import Categoria
from app.models.order import Pedido
from app.models.order_detail import DetallePedido


# Configurar Gemini si hay API key
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_DISPONIBLE = False
GEMINI_CLIENT = None

if GEMINI_API_KEY:
    try:
        GEMINI_CLIENT = genai.Client(api_key=GEMINI_API_KEY)
        GEMINI_DISPONIBLE = True
        print("✅ Gemini configurado correctamente")
    except Exception as e:
        print(f"⚠️ Gemini no se pudo configurar: {e}")


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