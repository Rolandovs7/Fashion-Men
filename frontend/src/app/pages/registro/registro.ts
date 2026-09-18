import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU03 - Registrar Usuario
// RF: RF01 - Registrar clientes
// CAPA: Angular | BACKEND: POST /api/auth/registro
// El rol siempre se crea como "cliente" en el backend (auth.py);
// el registro público no permite elegir rol.
// ============================================================
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
      'https://menstyle-api-n77g.onrender.com/api/auth/registro',
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
