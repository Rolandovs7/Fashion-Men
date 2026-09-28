import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Coleccion {
  id: number;
  nombre: string;
  descripcion?: string | null;
  activo: boolean;
}

export interface ColeccionCrear {
  nombre: string;
  descripcion?: string | null;
}

export interface ColeccionActualizar {
  nombre?: string;
  descripcion?: string | null;
  activo?: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class ColeccionesService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/colecciones';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listar(soloActivos = true): Observable<Coleccion[]> {
    return this.http.get<Coleccion[]>(
      `${this.apiUrl}?solo_activos=${soloActivos}`
    );
  }

  crear(datos: ColeccionCrear): Observable<Coleccion> {
    return this.http.post<Coleccion>(
      this.apiUrl,
      datos,
      { headers: this.headers() }
    );
  }

  eliminar(id: number): Observable<Coleccion> {
    return this.http.delete<Coleccion>(
      `${this.apiUrl}/${id}`,
      { headers: this.headers() }
    );
  }

  actualizar(id: number, datos: ColeccionActualizar): Observable<Coleccion> {
    return this.http.put<Coleccion>(
      `${this.apiUrl}/${id}`,
      datos,
      { headers: this.headers() }
    );
  }
}
