import { Component, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU04 - Recuperar Contraseña
// RF: RF02 - Recuperar contraseña vía email
// CAPA: Angular | SERVICIO: auth.service.ts | BACKEND: POST /api/auth/forgot-password
// ============================================================
@Component({
  selector: 'app-forgot-password',
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './forgot-password.html',
  styleUrl: './forgot-password.css'
})
export class ForgotPassword {
  private authService = inject(AuthService);
  private cdr = inject(ChangeDetectorRef);

  email = '';
  mensaje = '';
  error = '';
  cargando = false;
  enviado = false;

  enviarSolicitud(): void {
    this.error = '';
    this.mensaje = '';

    if (!this.email || !this.email.includes('@')) {
      this.error = 'Ingresá un correo electrónico válido.';
      return;
    }

    this.cargando = true;

    this.authService.solicitarResetPassword(this.email.trim()).subscribe({
      next: (respuesta) => {
        this.cargando = false;
        this.enviado = true;
        this.mensaje = respuesta.mensaje;
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.cargando = false;
        if (error.status === 429) {
          this.error = 'Demasiados intentos. Esperá unos minutos.';
        } else {
          this.error = 'No se pudo procesar la solicitud. Intentá de nuevo.';
        }
        this.cdr.detectChanges();
      }
    });
  }
}
