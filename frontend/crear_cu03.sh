#!/bin/bash

set -e

echo "🚀 Creando CU03 - Registrar Usuario..."

mkdir -p src/app/pages/registro

cat > src/app/pages/registro/registro.ts <<'EOF'
import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-registro',
  imports: [FormsModule],
  templateUrl: './registro.html',
  styleUrl: './registro.css'
})
export class Registro {

  private http = inject(HttpClient);
  private router = inject(Router);

  nombre = '';
  apellido = '';
  email = '';
  password = '';

  error = '';
  mensaje = '';
  cargando = false;

  registrar(): void {
    this.error = '';
    this.mensaje = '';

    if (!this.nombre || !this.apellido || !this.email || !this.password) {
      this.error = 'Completa todos los campos.';
      return;
    }

    this.cargando = true;

    const datos = {
      nombre: this.nombre,
      apellido: this.apellido,
      email: this.email,
      password: this.password
    };

    this.http.post(
      'http://127.0.0.1:8000/api/auth/registro',
      datos
    ).subscribe({
      next: () => {
        this.cargando = false;
        this.mensaje = 'Cuenta creada correctamente.';

        setTimeout(() => {
          this.router.navigate(['/login']);
        }, 1200);
      },
      error: (error) => {
        this.cargando = false;

        if (error.status === 400) {
          this.error = error.error?.detail || 'El email ya está registrado.';
        } else {
          this.error = 'No se pudo conectar con el servidor.';
        }
      }
    });
  }

  volverLogin(): void {
    this.router.navigate(['/login']);
  }
}
EOF

cat > src/app/pages/registro/registro.html <<'EOF'
<div class="registro-page">

  <div class="registro-card">

    <div class="brand">
      <h1>MENSTYLE</h1>
      <p>Moda masculina a tu estilo</p>
    </div>

    <h2>Crear cuenta</h2>
    <p class="subtitle">Regístrate para comenzar</p>

    @if (error) {
      <div class="error">
        {{ error }}
      </div>
    }

    @if (mensaje) {
      <div class="success">
        {{ mensaje }}
      </div>
    }

    <form (ngSubmit)="registrar()">

      <div class="row">

        <div class="field">
          <label for="nombre">Nombre</label>
          <input
            id="nombre"
            type="text"
            name="nombre"
            [(ngModel)]="nombre"
            placeholder="Tu nombre"
          />
        </div>

        <div class="field">
          <label for="apellido">Apellido</label>
          <input
            id="apellido"
            type="text"
            name="apellido"
            [(ngModel)]="apellido"
            placeholder="Tu apellido"
          />
        </div>

      </div>

      <div class="field">
        <label for="email">Correo electrónico</label>
        <input
          id="email"
          type="email"
          name="email"
          [(ngModel)]="email"
          placeholder="correo@ejemplo.com"
        />
      </div>

      <div class="field">
        <label for="password">Contraseña</label>
        <input
          id="password"
          type="password"
          name="password"
          [(ngModel)]="password"
          placeholder="Crea una contraseña"
        />
      </div>

      <button
        type="submit"
        [disabled]="cargando">

        @if (cargando) {
          Creando cuenta...
        } @else {
          Registrarse
        }

      </button>

    </form>

    <p class="login-link">
      ¿Ya tienes una cuenta?
      <a (click)="volverLogin()">Iniciar sesión</a>
    </p>

  </div>

</div>
EOF

cat > src/app/pages/registro/registro.css <<'EOF'
:host {
  display: block;
}

.registro-page {
  min-height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 24px;
  background: #f4f4f5;
}

.registro-card {
  width: 100%;
  max-width: 500px;
  background: white;
  border-radius: 20px;
  padding: 40px;
  box-shadow: 0 15px 45px rgba(0, 0, 0, 0.10);
}

.brand {
  text-align: center;
  margin-bottom: 28px;
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

h2 {
  margin-bottom: 6px;
  font-size: 26px;
}

.subtitle {
  color: #777;
  margin-top: 0;
  margin-bottom: 24px;
}

.row {
  display: flex;
  gap: 14px;
}

.row .field {
  flex: 1;
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
}

.error {
  padding: 12px;
  margin-bottom: 18px;
  border-radius: 8px;
  background: #fee2e2;
  color: #991b1b;
}

.success {
  padding: 12px;
  margin-bottom: 18px;
  border-radius: 8px;
  background: #dcfce7;
  color: #166534;
}

.login-link {
  text-align: center;
  margin-top: 24px;
  color: #666;
}

.login-link a {
  color: #111;
  font-weight: 600;
  cursor: pointer;
}
EOF

cat > src/app/app.routes.ts <<'EOF'
import { Routes } from '@angular/router';
import { Login } from './pages/login/login';
import { Inicio } from './pages/inicio/inicio';
import { Registro } from './pages/registro/registro';

export const routes: Routes = [
  {
    path: '',
    redirectTo: 'login',
    pathMatch: 'full'
  },
  {
    path: 'login',
    component: Login
  },
  {
    path: 'registro',
    component: Registro
  },
  {
    path: 'inicio',
    component: Inicio
  },
  {
    path: '**',
    redirectTo: 'login'
  }
];
EOF

echo "✅ CU03 creado."
echo "🚀 Ruta disponible: http://localhost:4200/registro"
