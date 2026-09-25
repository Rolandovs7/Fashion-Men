import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Temporada {
  id: number;
  nombre: string;
  descripcion?: string | null;
  activo: boolean;
}

export interface TemporadaCrear {
  nombre: string;
  descripcion?: string | null;
}

export interface TemporadaActualizar {
  nombre?: string;
  descripcion?: string | null;
  activo?: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class TemporadasService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/temporadas';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listar(soloActivos = true): Observable<Temporada[]> {
    return this.http.get<Temporada[]>(
      `${this.apiUrl}?solo_activos=${soloActivos}`
    );
  }

  crear(datos: TemporadaCrear): Observable<Temporada> {
    return this.http.post<Temporada>(
      this.apiUrl,
      datos,
      { headers: this.headers() }
    );
  }

  eliminar(id: number): Observable<Temporada> {
    return this.http.delete<Temporada>(
      `${this.apiUrl}/${id}`,
      { headers: this.headers() }
    );
  }

  actualizar(id: number, datos: TemporadaActualizar): Observable<Temporada> {
    return this.http.put<Temporada>(
      `${this.apiUrl}/${id}`,
      datos,
      { headers: this.headers() }
    );
  }
}
