import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU01 - Administrar Inicio de Sesión
// RF: RF01 - Registrar clientes (enlace a registro)
// CAPA: Angular | SERVICIO: auth.service.ts | BACKEND: POST /api/auth/login
// ============================================================
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
