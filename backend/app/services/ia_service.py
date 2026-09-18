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
from typing import Optional, List
from sqlalchemy.orm import Session
from sqlalchemy import desc, func

# --- Google Gemini (IA real) ---
import google.generativeai as genai

from app.models.product import Producto
from app.models.product_variant import ProductoVariante
from app.models.category import Categoria
from app.models.order import Pedido
from app.models.order_detail import DetallePedido


# Configurar Gemini si hay API key
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_DISPONIBLE = False

if GEMINI_API_KEY:
    try:
        genai.configure(api_key=GEMINI_API_KEY)
        GEMINI_DISPONIBLE = True
    except Exception as e:
        print(f"⚠️ Gemini no se pudo configurar: {e}")


class IAService:
    """
    Servicio de Inteligencia Artificial para MenStyle.

    Estrategia híbrida:
    1. Reglas rápidas (palabras clave) → respuestas instantáneas y gratis
    2. Google Gemini → cuando las reglas no matchean, IA real en lenguaje natural
    """

    # Contexto base del negocio para Gemini
    CONTEXTO_NEGOCIO = """
Eres el asistente virtual de "Fashion Men", una tienda de ropa masculina.
Ayudas a los clientes a encontrar prendas según categoría, ocasión, talla o precio.

Categorías típicas: Trajes, Camisas, Pantalones, Zapatos, Accesorios.
Ocasiones: formal (bodas, eventos), casual (diario), deportivo.
Tallas: S, M, L, XL, XXL.

Sé breve (máx 3 oraciones), amable y profesional. Responde SIEMPRE en español.
No inventes productos ni precios. Si no sabes algo, sugiere visitar el catálogo.
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
    def responder_consulta(self, mensaje: str) -> dict:
        """
        Asistente virtual híbrido:
        1. Primero intenta reglas rápidas (palabras clave)
        2. Si no matchea → consulta Gemini (IA real)
        3. Si Gemini falla → fallback genérico
        """
        msg = mensaje.lower().strip()
        productos_sugeridos = []

        # --- Detección por reglas (rápido, gratis) ---
        respuesta_por_reglas, productos_sugeridos, match = self._responder_con_reglas(msg)

        if match:
            return {
                "respuesta": respuesta_por_reglas,
                "productos_sugeridos": productos_sugeridos,
                "fuente": "reglas"
            }

        # --- Fallback: Gemini (IA real) ---
        if GEMINI_DISPONIBLE:
            respuesta_gemini = self._consultar_gemini(mensaje)
            if respuesta_gemini:
                return {
                    "respuesta": respuesta_gemini,
                    "productos_sugeridos": [],
                    "fuente": "gemini"
                }

        # --- Fallback final ---
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
        categorias_keywords = {
            "traje": "Traje", "trajes": "Traje",
            "camisa": "Camisa", "camisas": "Camisa",
            "pantalon": "Pantalón", "pantalones": "Pantalón", "jean": "Pantalón",
            "zapato": "Zapato", "zapatos": "Zapato",
            "accesorio": "Accesorio", "accesorios": "Accesorio",
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
                "¡Hola! Soy tu asistente de Fashion Men. "
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

    def _consultar_gemini(self, mensaje: str) -> Optional[str]:
        """
        Consulta a Google Gemini (IA real).
        Retorna la respuesta en texto, o None si falla.
        """
        try:
            model = genai.GenerativeModel("gemini-3.5-flash-lite")

            # Contexto con productos reales (para que no invente)
            productos_db = (
                self.db.query(Producto)
                .filter(Producto.activo == True)
                .limit(5)
                .all()
            )
            catalogo_ctx = "Productos destacados:\n"
            for p in productos_db:
                catalogo_ctx += f"- {p.nombre} (${float(p.precio)})\n"

            prompt = f"""{self.CONTEXTO_NEGOCIO}

{catalogo_ctx}

Cliente: {mensaje}
Asistente:"""

            response = model.generate_content(prompt)
            return response.text.strip()

        except Exception as e:
            print(f"⚠️ Error consultando Gemini: {e}")
            return None

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