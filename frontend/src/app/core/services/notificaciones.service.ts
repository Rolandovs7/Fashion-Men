import { Injectable, inject, signal } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, tap } from 'rxjs';

export interface Notificacion {
  id: number;
  usuario_id: number;
  titulo: string;
  mensaje: string;
  leida: boolean;
  fecha_creacion: string;
}

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU12 - Recibir Notificaciones
// RF: RF21 - Notificar cambios de estado
// CAPA: Angular | SERVICIO: notificaciones.service.ts
// BACKEND: GET /api/notificaciones, GET /api/notificaciones/no-leidas
//          PUT /api/notificaciones/{id}/leer
// ============================================================
@Injectable({
  providedIn: 'root'
})
export class NotificacionesService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/notificaciones';

  /** Signal reactivo con el número de no leídas. */
  readonly noLeidas = signal<number>(0);

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listar(): Observable<Notificacion[]> {
    return this.http.get<Notificacion[]>(`${this.apiUrl}`, { headers: this.headers() });
  }

  listarNoLeidas(): Observable<Notificacion[]> {
    return this.http.get<Notificacion[]>(`${this.apiUrl}/no-leidas`, { headers: this.headers() });
  }

  marcarComoLeida(id: number): Observable<Notificacion> {
    return this.http.put<Notificacion>(
      `${this.apiUrl}/${id}/leer`,
      {},
      { headers: this.headers() }
    ).pipe(
      tap(() => {
        // Actualizar el contador local
        this.noLeidas.update(n => Math.max(0, n - 1));
      })
    );
  }

  /** Refresca el contador de no leídas. */
  refrescarContador(): void {
    this.listarNoLeidas().subscribe({
      next: (n) => this.noLeidas.set(n.length),
      error: () => this.noLeidas.set(0)
    });
  }
}