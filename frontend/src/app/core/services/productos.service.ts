import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Producto {
  id: number;
  nombre: string;
  descripcion?: string | null;
  imagen_url?: string | null;
  precio: number;
  categoria_id: number;
  proveedor_id?: number | null;
  temporada_id?: number | null;
  coleccion_id?: number | null;
  tipo_prenda_id?: number | null;
  marca_id?: number | null;
  descuento_id?: number | null;
  activo: boolean;
}

export interface ProductoCrear {
  nombre: string;
  descripcion?: string | null;
  imagen_url?: string | null;
  precio: number;
  categoria_id: number;
  proveedor_id?: number | null;
  temporada_id?: number | null;
  coleccion_id?: number | null;
  tipo_prenda_id?: number | null;
  marca_id?: number | null;
  descuento_id?: number | null;
}

@Injectable({
  providedIn: 'root'
})
export class ProductosService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/productos';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listar(): Observable<Producto[]> {
    return this.http.get<Producto[]>(`${this.apiUrl}/`);
  }

  obtener(id: number): Observable<Producto> {
    return this.http.get<Producto>(`${this.apiUrl}/${id}`);
  }

  crear(datos: ProductoCrear): Observable<Producto> {
    return this.http.post<Producto>(
      `${this.apiUrl}/`,
      datos,
      { headers: this.headers() }
    );
  }

  actualizar(id: number, datos: ProductoCrear): Observable<Producto> {
    return this.http.put<Producto>(
      `${this.apiUrl}/${id}`,
      datos,
      { headers: this.headers() }
    );
  }

  cambiarActivo(id: number, activo: boolean): Observable<Producto> {
    return this.http.put<Producto>(
      `${this.apiUrl}/${id}`,
      { activo },
      { headers: this.headers() }
    );
  }

  eliminar(id: number): Observable<any> {
    return this.http.delete(
      `${this.apiUrl}/${id}`,
      { headers: this.headers() }
    );
  }
}
