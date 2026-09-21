import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable, tap } from 'rxjs';

export interface Usuario {
  id: number;
  nombre: string;
  apellido: string;
  email: string;
  activo: boolean;
  rol: string;
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
    const token = this.getToken();

    const headers = new HttpHeaders({
      Authorization: `Bearer ${token}`
    });

    return this.http.get<Usuario>(
      `${this.apiUrl}/me`,
      { headers }
    );
  }

  getToken(): string | null {
    return localStorage.getItem('access_token');
  }

  estaAutenticado(): boolean {
    return !!this.getToken();
  }

  logout(): void {
    localStorage.removeItem('access_token');
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
