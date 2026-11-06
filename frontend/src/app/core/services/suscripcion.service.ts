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

  cambiarPlan(plan_id: number): Observable<SuscripcionActual> {
    return this.http.put<SuscripcionActual>(`${this.apiUrl}/cambiar-plan`, { plan_id }, { headers: this.headers() });
  }
}
