#!/bin/bash

set -e

echo "🚀 Creando CU01 - Inicio de sesión..."

mkdir -p src/app/core/services
mkdir -p src/app/pages/login
mkdir -p src/app/pages/inicio

# =========================
# AUTH SERVICE
# =========================

cat > src/app/core/services/auth.service.ts <<'EOF'
import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable, tap } from 'rxjs';

export interface Usuario {
  id: number;
  nombre: string;
  apellido: string;
  email: string;
  activo: boolean;
}

export interface Token {
  access_token: string;
  token_type: string;
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {

  private http = inject(HttpClient);

  private apiUrl = 'http://127.0.0.1:8000/api/auth';

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
}
EOF

# =========================
# LOGIN TS
# =========================

cat > src/app/pages/login/login.ts <<'EOF'
import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-login',
  imports: [FormsModule],
  templateUrl: './login.html',
  styleUrl: './login.css'
})
export class Login {

  private authService = inject(AuthService);
  private router = inject(Router);

  email = '';
  password = '';
  error = '';
  cargando = false;

  iniciarSesion(): void {
    this.error = '';

    if (!this.email || !this.password) {
      this.error = 'Completa todos los campos.';
      return;
    }

    this.cargando = true;

    this.authService.login(this.email, this.password).subscribe({
      next: () => {
        this.authService.obtenerUsuarioActual().subscribe({
          next: () => {
            this.cargando = false;
            this.router.navigate(['/inicio']);
          },
          error: () => {
            this.cargando = false;
            this.error = 'No se pudo obtener la información del usuario.';
          }
        });
      },
      error: (error) => {
        this.cargando = false;

        if (error.status === 401) {
          this.error = 'Email o contraseña incorrectos.';
        } else {
          this.error = 'No se pudo conectar con el servidor.';
        }
      }
    });
  }
}
EOF

# =========================
# LOGIN HTML
# =========================

cat > src/app/pages/login/login.html <<'EOF'
<div class="login-page">

  <div class="login-card">

    <div class="brand">
      <h1>MENSTYLE</h1>
      <p>Moda masculina a tu estilo</p>
    </div>

    <div class="login-content">
      <h2>Iniciar sesión</h2>
      <p class="subtitle">Ingresa a tu cuenta</p>

      @if (error) {
        <div class="error">
          {{ error }}
        </div>
      }

      <form (ngSubmit)="iniciarSesion()">

        <div class="field">
          <label for="email">Correo electrónico</label>
          <input
            id="email"
            type="email"
            name="email"
            [(ngModel)]="email"
            placeholder="correo@ejemplo.com"
            autocomplete="email"
          />
        </div>

        <div class="field">
          <label for="password">Contraseña</label>
          <input
            id="password"
            type="password"
            name="password"
            [(ngModel)]="password"
            placeholder="Tu contraseña"
            autocomplete="current-password"
          />
        </div>

        <button
          type="submit"
          [disabled]="cargando">

          @if (cargando) {
            Iniciando sesión...
          } @else {
            Iniciar sesión
          }

        </button>

      </form>

      <p class="register">
        ¿No tienes una cuenta?
        <a href="/registro">Crear cuenta</a>
      </p>

    </div>

  </div>

</div>
EOF

# =========================
# LOGIN CSS
# =========================

cat > src/app/pages/login/login.css <<'EOF'
:host {
  display: block;
}

.login-page {
  min-height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 24px;
  background: #f4f4f5;
}

.login-card {
  width: 100%;
  max-width: 430px;
  background: white;
  border-radius: 20px;
  padding: 40px;
  box-shadow: 0 15px 45px rgba(0, 0, 0, 0.10);
}

.brand {
  text-align: center;
  margin-bottom: 32px;
}

.brand h1 {
  margin: 0;
  font-size: 28px;
  letter-spacing: 4px;
}

.brand p {
  color: #777;
  margin-top: 8px;
}

.login-content h2 {
  margin-bottom: 6px;
  font-size: 26px;
}

.subtitle {
  color: #777;
  margin-top: 0;
  margin-bottom: 24px;
}

.field {
  margin-bottom: 18px;
}

.field label {
  display: block;
  margin-bottom: 7px;
  font-weight: 600;
}

.field input {
  width: 100%;
  box-sizing: border-box;
  padding: 13px 14px;
  border: 1px solid #ddd;
  border-radius: 10px;
  font-size: 15px;
}

.field input:focus {
  outline: none;
  border-color: #111;
}

button {
  width: 100%;
  padding: 14px;
  border: none;
  border-radius: 10px;
  background: #111;
  color: white;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
}

button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.error {
  padding: 12px;
  margin-bottom: 18px;
  border-radius: 8px;
  background: #fee2e2;
  color: #991b1b;
}

.register {
  text-align: center;
  margin-top: 24px;
  color: #666;
}

.register a {
  color: #111;
  font-weight: 600;
}
EOF

# =========================
# INICIO TS
# =========================

cat > src/app/pages/inicio/inicio.ts <<'EOF'
import { Component, inject } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService, Usuario } from '../../core/services/auth.service';

@Component({
  selector: 'app-inicio',
  imports: [],
  templateUrl: './inicio.html',
  styleUrl: './inicio.css'
})
export class Inicio {

  private authService = inject(AuthService);
  private router = inject(Router);

  usuario: Usuario | null = null;

  constructor() {
    this.authService.obtenerUsuarioActual().subscribe({
      next: (usuario) => {
        this.usuario = usuario;
      },
      error: () => {
        this.router.navigate(['/login']);
      }
    });
  }

  cerrarSesion(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}
EOF

# =========================
# INICIO HTML
# =========================

cat > src/app/pages/inicio/inicio.html <<'EOF'
<div class="inicio">

  <header>
    <h1>MENSTYLE</h1>

    <button (click)="cerrarSesion()">
      Cerrar sesión
    </button>
  </header>

  <main>

    @if (usuario) {
      <h2>Bienvenido, {{ usuario.nombre }} 👋</h2>

      <p>
        Has iniciado sesión correctamente.
      </p>

      <div class="user-card">
        <strong>Cuenta</strong>
        <p>{{ usuario.nombre }} {{ usuario.apellido }}</p>
        <p>{{ usuario.email }}</p>
      </div>
    }

  </main>

</div>
EOF

# =========================
# INICIO CSS
# =========================

cat > src/app/pages/inicio/inicio.css <<'EOF'
.inicio {
  min-height: 100vh;
  background: #f4f4f5;
}

header {
  background: #111;
  color: white;
  padding: 18px 40px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

header h1 {
  margin: 0;
  letter-spacing: 3px;
}

header button {
  background: white;
  color: #111;
  border: none;
  border-radius: 8px;
  padding: 10px 16px;
  cursor: pointer;
}

main {
  max-width: 1000px;
  margin: 50px auto;
  padding: 0 24px;
}

.user-card {
  margin-top: 30px;
  padding: 25px;
  background: white;
  border-radius: 15px;
  box-shadow: 0 5px 20px rgba(0,0,0,.06);
}
EOF

echo "✅ Archivos de CU01 creados."
