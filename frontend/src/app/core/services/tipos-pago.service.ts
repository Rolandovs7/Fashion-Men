import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface TipoPago {
  id: number;
  nombre: string;
  activo: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class TiposPagoService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-hms1.onrender.com/api/tipos-pago';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listar(soloActivos = true): Observable<TipoPago[]> {
    return this.http.get<TipoPago[]>(`${this.apiUrl}?solo_activos=${soloActivos}`);
  }

  crear(nombre: string): Observable<TipoPago> {
    return this.http.post<TipoPago>(this.apiUrl, { nombre }, { headers: this.headers() });
  }

  eliminar(id: number): Observable<TipoPago> {
    return this.http.delete<TipoPago>(`${this.apiUrl}/${id}`, { headers: this.headers() });
  }
}
