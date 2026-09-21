import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface ProductoSugerido {
  id: number;
  nombre: string;
  descripcion: string;
  precio: number;
  categoria_id: number;
  motivo: string;
}

export interface ChatResponse {
  respuesta: string;
  productos_sugeridos: ProductoSugerido[];
  fuente?: string;
}

export interface MensajeChat {
  rol: 'usuario' | 'bot';
  texto: string;
  productos?: ProductoSugerido[];
  hora: Date;
}

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU32 - Interactuar con Asistente Virtual
// RF: RF25 - Funcionalidad basada en IA
// CAPA: Angular | SERVICIO: ia.service.ts
// BACKEND: POST /api/ia/chat, GET /api/ia/tendencias
// ============================================================
@Injectable({
  providedIn: 'root'
})
export class IaService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/ia';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      'Content-Type': 'application/json'
    });
  }

  enviarMensaje(mensaje: string): Observable<ChatResponse> {
    return this.http.post<ChatResponse>(
      `${this.apiUrl}/chat`,
      { mensaje },
      { headers: this.headers() }
    );
  }

  obtenerTendencias(limite: number = 5): Observable<{ total: number; productos: ProductoSugerido[] }> {
    return this.http.get<{ total: number; productos: ProductoSugerido[] }>(
      `${this.apiUrl}/tendencias?limite=${limite}`
    );
  }
}