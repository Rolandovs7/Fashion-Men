import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Variante {
  id: number;
  producto_id: number;
  talla_id: number;
  talla_nombre: string;
  color_id: number;
  color_nombre: string;
  color_codigo_hex?: string | null;
  color_imagen_url?: string | null;
  nombre_variante?: string | null;
  activo: boolean;
  stock_disponible: number;
}

export interface VarianteCrear {
  producto_id: number;
  talla_id: number;
  color_id: number;
  nombre_variante?: string | null;
}

export interface Talla {
  id: number;
  nombre: string;
  activo: boolean;
}

export interface Color {
  id: number;
  nombre: string;
  codigo_hex?: string | null;
  imagen_url?: string | null;
  activo: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class VariantesService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listarPorProducto(productoId: number): Observable<Variante[]> {
    return this.http.get<Variante[]>(
      `${this.apiUrl}/variantes/producto/${productoId}`
    );
  }

  obtenerPorId(varianteId: number): Observable<Variante> {
    return this.http.get<Variante>(
      `${this.apiUrl}/variantes/${varianteId}`
    );
  }

  crear(datos: VarianteCrear): Observable<Variante> {
    return this.http.post<Variante>(
      `${this.apiUrl}/variantes`,
      datos,
      { headers: this.headers() }
    );
  }

  actualizarVariante(
    id: number,
    datos: { activo?: boolean; nombre_variante?: string | null }
  ): Observable<Variante> {
    return this.http.put<Variante>(
      `${this.apiUrl}/variantes/${id}`,
      datos,
      { headers: this.headers() }
    );
  }

  listarTallas(): Observable<Talla[]> {
    return this.http.get<Talla[]>(`${this.apiUrl}/tallas`);
  }

  crearTalla(nombre: string): Observable<Talla> {
    return this.http.post<Talla>(
      `${this.apiUrl}/tallas`,
      { nombre },
      { headers: this.headers() }
    );
  }

  eliminarTalla(id: number): Observable<Talla> {
    return this.http.delete<Talla>(
      `${this.apiUrl}/tallas/${id}`,
      { headers: this.headers() }
    );
  }

  listarColores(): Observable<Color[]> {
    return this.http.get<Color[]>(`${this.apiUrl}/colores`);
  }

  actualizarColor(
    id: number,
    datos: { nombre?: string; codigo_hex?: string | null; imagen_url?: string | null; activo?: boolean }
  ): Observable<Color> {
    return this.http.put<Color>(
      `${this.apiUrl}/colores/${id}`,
      datos,
      { headers: this.headers() }
    );
  }

  crearColor(nombre: string, codigoHex: string | null, imagenUrl: string | null = null): Observable<Color> {
    return this.http.post<Color>(
      `${this.apiUrl}/colores`,
      { nombre, codigo_hex: codigoHex, imagen_url: imagenUrl },
      { headers: this.headers() }
    );
  }

  eliminarColor(id: number): Observable<Color> {
    return this.http.delete<Color>(
      `${this.apiUrl}/colores/${id}`,
      { headers: this.headers() }
    );
  }
}
