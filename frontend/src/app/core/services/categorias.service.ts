import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Categoria {
  id: number;
  nombre: string;
  descripcion?: string | null;
  activo: boolean;
}

export interface CategoriaCrear {
  nombre: string;
  descripcion?: string | null;
  activo?: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class CategoriasService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/categorias';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listar(soloActivos = true): Observable<Categoria[]> {
    return this.http.get<Categoria[]>(
      `${this.apiUrl}?solo_activos=${soloActivos}`
    );
  }

  crear(datos: CategoriaCrear): Observable<Categoria> {
    return this.http.post<Categoria>(
      this.apiUrl,
      datos,
      { headers: this.headers() }
    );
  }

  actualizar(id: number, datos: CategoriaCrear): Observable<Categoria> {
    return this.http.put<Categoria>(
      `${this.apiUrl}/${id}`,
      datos,
      { headers: this.headers() }
    );
  }

  eliminar(id: number): Observable<Categoria> {
    return this.http.delete<Categoria>(
      `${this.apiUrl}/${id}`,
      { headers: this.headers() }
    );
  }
}
