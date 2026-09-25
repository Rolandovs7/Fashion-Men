import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Descuento {
  id: number;
  nombre: string;
  porcentaje: number;
  fecha_inicio?: string | null;
  fecha_fin?: string | null;
  activo: boolean;
}

export interface DescuentoCrear {
  nombre: string;
  porcentaje: number;
  fecha_inicio?: string | null;
  fecha_fin?: string | null;
}

export interface DescuentoActualizar {
  nombre?: string;
  porcentaje?: number;
  fecha_inicio?: string | null;
  fecha_fin?: string | null;
  activo?: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class DescuentosService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/descuentos';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listar(soloActivos = false): Observable<Descuento[]> {
    return this.http.get<Descuento[]>(`${this.apiUrl}?solo_activos=${soloActivos}`);
  }

  crear(datos: DescuentoCrear): Observable<Descuento> {
    return this.http.post<Descuento>(this.apiUrl, datos, { headers: this.headers() });
  }

  eliminar(id: number): Observable<Descuento> {
    return this.http.delete<Descuento>(`${this.apiUrl}/${id}`, { headers: this.headers() });
  }

  actualizar(id: number, datos: DescuentoActualizar): Observable<Descuento> {
    return this.http.put<Descuento>(`${this.apiUrl}/${id}`, datos, { headers: this.headers() });
  }
}
