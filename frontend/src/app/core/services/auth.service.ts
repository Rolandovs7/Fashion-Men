import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable, of, tap } from 'rxjs';

export interface Usuario {
  id: number;
  nombre: string;
  apellido: string;
  email: string;
  activo: boolean;
  rol: string;
  empresa_id?: number | null;
  empresa_nombre?: string | null;
  sucursal_id?: number | null;
}

export interface Token {
  access_token: string;
  token_type: string;
}

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU01 - Administrar Inicio de Sesión
// CU: CU02 - Administrar Cierre de Sesión
// RF: RF01 - Registrar clientes (registro relacionado, ver registro.ts)
// CAPA: Angular
// SERVICIO: core/services/auth.service.ts
// PANTALLA: pages/login, pages/registro
// BACKEND: POST /api/auth/login, GET /api/auth/me
// El logout es local (localStorage.removeItem) porque el backend usa
// JWT sin blacklist de tokens — no existe endpoint de logout.
// ============================================================
@Injectable({
  providedIn: 'root'
})
export class AuthService {

  private http = inject(HttpClient);

  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/auth';

  login(email: string, password: string): Observable<Token> {
    const body = new HttpParams()
      .set('username', email)
      .set('password', password);

    const headers = new HttpHeaders({
      'Content-Type': 'application/x-www-form-urlencoded'
    });

    return this.http.post<Token>(
      `${this.apiUrl}/login`,
      body.toString(),
      { headers }
    ).pipe(
      tap(response => {
        localStorage.setItem('access_token', response.access_token);
      })
    );
  }

  obtenerUsuarioActual(): Observable<Usuario> {
    if (typeof navigator !== 'undefined' && !navigator.onLine && this.getToken()) {
      const cached = (() => {
        try {
          const raw = localStorage.getItem('menstyle_usuario_actual');
          return raw ? JSON.parse(raw) : null;
        } catch {
          return null;
        }
      })();
      if (cached) {
        return of(cached);
      }
    }
    const token = this.getToken();

    const headers = new HttpHeaders({
      Authorization: `Bearer ${token}`
    });

    return this.http.get<Usuario>(
      `${this.apiUrl}/me`,
      { headers }
    ).pipe(
      tap((usuario) => {
        try {
          localStorage.setItem('menstyle_usuario_actual', JSON.stringify(usuario));
        } catch {
          // ignore
        }
      })
    );
  }

  /** Nombre de la empresa del usuario autenticado (branding dinámico). */
  nombreEmpresa(): string {
    try {
      const raw = localStorage.getItem('menstyle_usuario_actual');
      if (raw) {
        const usuario = JSON.parse(raw) as Usuario;
        const nombre = (usuario?.empresa_nombre ?? '').toString().trim();
        if (nombre) return nombre;
      }
    } catch {
      // ignore
    }
    return 'MenStyle';
  }

  getToken(): string | null {
    return localStorage.getItem('access_token');
  }

  estaAutenticado(): boolean {
    if (typeof navigator !== 'undefined' && !navigator.onLine && this.getToken()) {
      return true;
    }
    return !!this.getToken();
  }

  logout(): void {
    localStorage.removeItem('access_token');
    localStorage.removeItem('menstyle_usuario_actual');
  }
  
    solicitarResetPassword(email: string): Observable<{ mensaje: string }> {
    return this.http.post<{ mensaje: string }>(
      `${this.apiUrl}/forgot-password`,
      { email }
    );
  }

  resetPassword(token: string, passwordNueva: string): Observable<{ mensaje: string }> {
    return this.http.post<{ mensaje: string }>(
      `${this.apiUrl}/reset-password`,
      { token, password_nueva: passwordNueva }
    );
  }
}
