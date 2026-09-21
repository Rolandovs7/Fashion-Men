import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU04 - Recuperar Contraseña
// RF: RF02 - Recuperar contraseña vía email
// CAPA: Angular | SERVICIO: auth.service.ts | BACKEND: POST /api/auth/reset-password
// ============================================================
@Component({
  selector: 'app-reset-password',
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './reset-password.html',
  styleUrl: './reset-password.css'
})
export class ResetPassword implements OnInit {
  private authService = inject(AuthService);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private cdr = inject(ChangeDetectorRef);

  token = '';
  passwordNueva = '';
  passwordConfirm = '';
  mostrarPassword = false;

  cargando = false;
  error = '';
  exito = false;

  ngOnInit(): void {
    this.token = this.route.snapshot.queryParamMap.get('token') ?? '';
    if (!this.token) {
      this.error = 'Token no encontrado en la URL. Solicitá un nuevo link.';
    }
  }

  get reglas() {
    const p = this.passwordNueva;
    return {
      longitud: p.length >= 8,
      mayuscula: /[A-Z]/.test(p),
      minuscula: /[a-z]/.test(p),
      numero: /[0-9]/.test(p),
      simbolo: /[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/.test(p),
    };
  }

  get passwordValida(): boolean {
    const r = this.reglas;
    return r.longitud && r.mayuscula && r.minuscula && r.numero && r.simbolo;
  }

  get passwordsCoinciden(): boolean {
    return this.passwordNueva === this.passwordConfirm && this.passwordNueva.length > 0;
  }

  enviarReset(): void {
    this.error = '';

    if (!this.token) {
      this.error = 'Token inválido. Solicitá un nuevo link.';
      return;
    }

    if (!this.passwordValida) {
      this.error = 'La contraseña no cumple todos los requisitos.';
      return;
    }

    if (!this.passwordsCoinciden) {
      this.error = 'Las contraseñas no coinciden.';
      return;
    }

    this.cargando = true;

    this.authService.resetPassword(this.token, this.passwordNueva).subscribe({
      next: () => {
        this.cargando = false;
        this.exito = true;
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.cargando = false;
        const detail = error.error?.detail;
        if (typeof detail === 'string') {
          this.error = detail;
        } else if (Array.isArray(detail) && detail[0]?.msg) {
          this.error = detail[0].msg;
        } else {
          this.error = 'No se pudo cambiar la contraseña. Intentá de nuevo.';
        }
        this.cdr.detectChanges();
      }
    });
  }
}
