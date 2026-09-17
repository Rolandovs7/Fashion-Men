import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface DetalleReservaItem {
  variante_id: number;
  cantidad: number;
}

export interface DetalleReserva {
  id: number;
  reserva_id: number;
  variante_id: number;
  cantidad: number;
}

export interface Reserva {
  id: number;
  usuario_id: number;
  sucursal_id: number;
  fecha_reserva: string;
  estado: string;
  observaciones?: string | null;
  detalles: DetalleReserva[];
}

export interface ReservaCrear {
  sucursal_id: number;
  fecha_reserva: string;
  observaciones?: string | null;
  detalles: DetalleReservaItem[];
}

@Injectable({
  providedIn: 'root'
})
export class ReservasService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-hms1.onrender.com/api/reservas';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listarMisReservas(estado?: string): Observable<Reserva[]> {
    const query = estado ? `?estado=${estado}` : '';
    return this.http.get<Reserva[]>(
      `${this.apiUrl}${query}`,
      { headers: this.headers() }
    );
  }

  obtener(id: number): Observable<Reserva> {
    return this.http.get<Reserva>(
      `${this.apiUrl}/${id}`,
      { headers: this.headers() }
    );
  }

  crear(datos: ReservaCrear): Observable<Reserva> {
    return this.http.post<Reserva>(
      this.apiUrl,
      datos,
      { headers: this.headers() }
    );
  }

  cancelar(id: number): Observable<Reserva> {
    return this.http.put<Reserva>(
      `${this.apiUrl}/${id}/cancelar`,
      {},
      { headers: this.headers() }
    );
  }

  // ----- Administración / encargado de sucursal -----
  listarTodas(estado?: string, sucursalId?: number): Observable<Reserva[]> {
    const params = new URLSearchParams();
    if (estado) params.set('estado', estado);
    if (sucursalId) params.set('sucursal_id', String(sucursalId));
    const query = params.toString() ? `?${params.toString()}` : '';

    return this.http.get<Reserva[]>(
      `${this.apiUrl}/admin/todas${query}`,
      { headers: this.headers() }
    );
  }

  cambiarEstado(id: number, nuevoEstado: string): Observable<Reserva> {
    return this.http.put<Reserva>(
      `${this.apiUrl}/${id}/estado`,
      { nuevo_estado: nuevoEstado },
      { headers: this.headers() }
    );
  }
}
