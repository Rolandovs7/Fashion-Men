import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';

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
  private cacheKey = 'menstyle_cache_categorias';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listar(soloActivos = true): Observable<Categoria[]> {
    if (!navigator.onLine) {
      try {
        const cached = localStorage.getItem(this.cacheKey);
        if (cached) {
          const data = JSON.parse(cached) as Categoria[];
          return of(soloActivos ? data.filter(d => d.activo) : data);
        }
      } catch {
        // ignore
      }
      return of([]);
    }
    return this.http.get<Categoria[]>(
      `${this.apiUrl}?solo_activos=${soloActivos}`
    ).pipe(
      tap((data) => {
        try {
          localStorage.setItem(this.cacheKey, JSON.stringify(data));
        } catch {
          // ignore
        }
      })
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
