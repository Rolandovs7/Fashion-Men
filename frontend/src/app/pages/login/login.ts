import { Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';
import { ButtonComponent, InputComponent, AlertComponent } from '../../shared/ui';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU01 - Administrar Inicio de Sesión
// CU: CU04 - Recuperar Contraseña (link a forgot-password)
// RF: RF01 - Registrar clientes (enlace a registro)
// CAPA: Angular | SERVICIO: auth.service.ts | BACKEND: POST /api/auth/login
// ============================================================
@Component({
  selector: 'app-login',
  imports: [FormsModule, RouterLink, ButtonComponent, InputComponent, AlertComponent],
  templateUrl: './login.html',
  styleUrl: './login.css'
})
export class Login implements OnInit {

  private authService = inject(AuthService);
  private router = inject(Router);
  private route = inject(ActivatedRoute);

  email = '';
  password = '';
  error = '';
  cargando = false;
  mostrarPassword = false;

  /** Conserva /login?empresa_id=2 al ir al registro de esa tienda. */
  empresaId: number | null = null;

  ngOnInit(): void {
    const param = Number(this.route.snapshot.queryParamMap.get('empresa_id'));
    this.empresaId = Number.isFinite(param) && param > 0 ? param : null;
  }

  get empresaNombre(): string {
    return this.authService.nombreEmpresa();
  }

  get registroQueryParams(): Record<string, number> {
    return this.empresaId != null ? { empresa_id: this.empresaId } : {};
  }

  togglePassword(): void {
    this.mostrarPassword = !this.mostrarPassword;
  }

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
        } else if (error.status === 429) {
          this.error = 'Demasiados intentos. Esperá unos minutos.';
        } else {
          this.error = 'No se pudo conectar con el servidor.';
        }
      }
    });
  }
}