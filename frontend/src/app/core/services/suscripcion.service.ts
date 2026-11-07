import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Plan {
  id: number;
  nombre: string;
  max_sucursales: number;
  permite_ia: boolean;
  permite_offline: boolean;
  precio_mensual: number | string;
  descripcion?: string | null;
}

export interface SuscripcionActual {
  id: number;
  empresa_id: number;
  plan: Plan;
  fecha_inicio: string;
  fecha_fin?: string | null;
  estado: string;
}

/** [Segundo Parcial] CU02 - Inicio checkout simulado */
export interface CheckoutPlanResponse {
  checkout_url: string;
  plan_id: number;
  plan_nombre: string;
  monto: number | string;
}

@Injectable({
  providedIn: 'root'
})
export class SuscripcionService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/suscripciones';

  private headers(): HttpHeaders {
    const token = localStorage.getItem('access_token');
    return new HttpHeaders({
      'Content-Type': 'application/json',
      ...(token ? { 'Authorization': `Bearer ${token}` } : {})
    });
  }

  listarPlanes(): Observable<Plan[]> {
    return this.http.get<Plan[]>(`${this.apiUrl}/planes`, { headers: this.headers() });
  }

  obtenerMiSuscripcion(): Observable<SuscripcionActual> {
    return this.http.get<SuscripcionActual>(`${this.apiUrl}/mi-suscripcion`, { headers: this.headers() });
  }

  /** [Segundo Parcial] CU02 - Inicia checkout (devuelve checkout_url simulado, no cambia el plan). */
  iniciarCheckout(plan_id: number): Observable<CheckoutPlanResponse> {
    return this.http.put<CheckoutPlanResponse>(`${this.apiUrl}/cambiar-plan`, { plan_id }, { headers: this.headers() });
  }

  /** [Segundo Parcial] CU02 - Confirma pago simulado y aplica cambio real. */
  confirmarPago(plan_id: number, payment_status = 'success'): Observable<SuscripcionActual> {
    return this.http.post<SuscripcionActual>(`${this.apiUrl}/confirmar-pago`, { plan_id, payment_status }, { headers: this.headers() });
  }
}
