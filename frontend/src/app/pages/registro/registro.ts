import { Component, inject, ChangeDetectorRef } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { ButtonComponent, InputComponent, AlertComponent } from '../../shared/ui';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU03 - Registrar Usuario
// RF: RF01 - Registrar clientes
// CAPA: Angular | BACKEND: POST /api/auth/registro
// El rol siempre se crea como "cliente" en el backend (auth.py);
// el registro público no permite elegir rol.
// El campo "Nombre completo" se divide en nombre + apellido
// para respetar el contrato del backend.
// ============================================================
@Component({
  selector: 'app-registro',
  imports: [FormsModule, RouterLink, ButtonComponent, InputComponent, AlertComponent],
  templateUrl: './registro.html',
  styleUrl: './registro.css'
})
export class Registro {

  private http = inject(HttpClient);
  private router = inject(Router);
  private cdr = inject(ChangeDetectorRef);

  nombre = '';
  email = '';
  password = '';
  password2 = '';
  aceptaTerminos = false;

  error = '';
  errorPassword2 = '';
  mensaje = '';
  cargando = false;

  registrar(): void {
    this.error = '';
    this.errorPassword2 = '';
    this.mensaje = '';

    if (!this.nombre.trim() || !this.email || !this.password) {
      this.error = 'Completa todos los campos obligatorios.';
      return;
    }

    if (this.password !== this.password2) {
      this.errorPassword2 = 'Las contraseñas no coinciden.';
      return;
    }

    if (!this.aceptaTerminos) {
      this.error = 'Debés aceptar los términos y condiciones para continuar.';
      return;
    }

    this.cargando = true;

    const partes = this.nombre.trim().split(/\s+/);
    const nombre = partes[0];
    const apellido = partes.slice(1).join(' ');

    const datos = {
      nombre: nombre,
      apellido: apellido,
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
        this.cdr.detectChanges();

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
        this.cdr.detectChanges();
      }
    });
  }
}