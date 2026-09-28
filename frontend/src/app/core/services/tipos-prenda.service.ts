import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface TipoPrenda {
  id: number;
  nombre: string;
  descripcion?: string | null;
  activo: boolean;
}

export interface TipoPrendaActualizar {
  nombre?: string;
  descripcion?: string | null;
  activo?: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class TiposPrendaService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/tipos-prenda';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listar(soloActivos = false): Observable<TipoPrenda[]> {
    return this.http.get<TipoPrenda[]>(`${this.apiUrl}?solo_activos=${soloActivos}`);
  }

  crear(nombre: string, descripcion: string | null): Observable<TipoPrenda> {
    return this.http.post<TipoPrenda>(this.apiUrl, { nombre, descripcion }, { headers: this.headers() });
  }

  eliminar(id: number): Observable<TipoPrenda> {
    return this.http.delete<TipoPrenda>(`${this.apiUrl}/${id}`, { headers: this.headers() });
  }

  actualizar(id: number, datos: TipoPrendaActualizar): Observable<TipoPrenda> {
    return this.http.put<TipoPrenda>(`${this.apiUrl}/${id}`, datos, { headers: this.headers() });
  }
}
