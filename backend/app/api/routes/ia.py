# ============================================================
# TRAZABILIDAD MENSTYLE
# CU: CU31 - Recibir Recomendaciones (IA)
# CU: CU32 - Interactuar con Asistente Virtual
# CU: CU30 - Generar Reportes (tendencias)
# RF: RF25 - Proporcionar funcionalidad basada en inteligencia artificial
# ENDPOINT: POST /api/ia/recomendar, POST /api/ia/chat, GET /api/ia/tendencias
# CAPA: Backend FastAPI (Routes)
# ============================================================
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.dependencies import obtener_db, obtener_usuario_actual, requerir_suscripcion_vigente
from app.models.user import Usuario
from app.services.ia_service import IAService
from app.schemas.ia import (
    RecomendacionRequest,
    RecomendacionResponse,
    ChatRequest,
    ChatResponse,
    TendenciaResponse,
)

router = APIRouter(tags=["Inteligencia Artificial"])


@router.post("/recomendar", response_model=RecomendacionResponse)
def recomendar_prendas(
    req: RecomendacionRequest,
    db: Session = Depends(obtener_db),
    usuario: Usuario = Depends(obtener_usuario_actual),
    _suscripcion=Depends(requerir_suscripcion_vigente),
):
    """
    CU31 - Recibir Recomendaciones (IA)
    RF25 - Recomendador personalizado basado en historial + categoría.
    """
    service = IAService(db)
    resultado = service.recomendar_para_usuario(
        usuario_id=usuario.id,
        categoria_id=req.categoria_id,
        tipo_prenda_id=req.tipo_prenda_id,
        limite=req.limite
    )
    return resultado


@router.post("/chat", response_model=ChatResponse)
def chat_asistente(
    req: ChatRequest,
    db: Session = Depends(obtener_db)
):
    """
    CU32 - Interactuar con Asistente Virtual
    RF25 - Asistente que responde según palabras clave y sugiere productos.
    No requiere autenticación (público).
    """
    service = IAService(db)
    return service.responder_consulta(req.mensaje, historial=req.historial)


@router.get("/tendencias", response_model=TendenciaResponse)
def productos_tendencia(
    limite: int = 5,
    db: Session = Depends(obtener_db)
):
    """
    CU30 - Generar Reportes (tendencias)
    RF24 - Productos más vendidos para dashboard.
    """
    service = IAService(db)
    return service.productos_tendencia(limite)

# ============================================================
# [Segundo Parcial] CU23 - Reportes Generativos (Text-to-SQL)
# [Segundo Parcial] RN-IA-01 - Seguridad SQL
# ============================================================
from app.schemas.ia import ConsultarIARequest, ConsultarIAResponse, PrediccionesResponse
from app.core.dependencies import get_current_empresa_id


@router.post("/consultar", response_model=ConsultarIAResponse)
def consultar_ia_natural(
    req: ConsultarIARequest,
    db: Session = Depends(obtener_db),
    usuario: Usuario = Depends(obtener_usuario_actual),
    empresa_id: int = Depends(get_current_empresa_id),
    _suscripcion=Depends(requerir_suscripcion_vigente),
):
    """
    CU23 - Reportes Generativos (Text-to-SQL con Gemini)
    RN-IA-01 - Solo SELECT, sin comandos destructivos, filtro empresa_id obligatorio
    """
    service = IAService(db)
    try:
        resultado = service.consultar_sql_natural(req.pregunta, empresa_id)
        return resultado
    except ValueError as e:
        return {"sql": "", "columnas": [], "resultados": [], "mensaje": str(e)}


# ============================================================
# [Segundo Parcial] CU24 - Machine Learning (Predicciones)
# ============================================================
@router.get("/predicciones", response_model=PrediccionesResponse)
def obtener_predicciones(
    db: Session = Depends(obtener_db),
    usuario: Usuario = Depends(obtener_usuario_actual),
    empresa_id: int = Depends(get_current_empresa_id),
    _suscripcion=Depends(requerir_suscripcion_vigente),
):
    """
    CU24 - Machine Learning (Modelo Predictivo)
    Devuelve datos históricos y predicción de ventas próximo mes
    """
    service = IAService(db)
    return service.predecir_ventas(empresa_id)
