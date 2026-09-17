import { Component, inject, OnInit, ChangeDetectorRef } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService, Usuario } from '../../core/services/auth.service';
import { HeaderComponent } from '../../shared/header/header';

@Component({
  selector: 'app-inicio',
  imports: [HeaderComponent],
  templateUrl: './inicio.html',
  styleUrl: './inicio.css'
})
export class Inicio implements OnInit {

  private authService = inject(AuthService);
  private router = inject(Router);
  private cdr = inject(ChangeDetectorRef);

  usuario: Usuario | null = null;

  ngOnInit(): void {
    this.authService.obtenerUsuarioActual().subscribe({
      next: (usuario) => {
        console.log('USUARIO RECIBIDO POR ANGULAR:', usuario);

        this.usuario = usuario;

        // Fuerza a Angular a actualizar la pantalla
        this.cdr.detectChanges();
      },
      error: (error) => {
        console.error('ERROR AL CARGAR USUARIO:', error);
        this.router.navigate(['/login']);
      }
    });
  }

  cerrarSesion(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }

  irUsuarios(): void {
    this.router.navigate(['/usuarios']);
  }

  irPermisos(): void {
  this.router.navigate(['/permisos']);
  }

  irCatalogo(): void {
    this.router.navigate(['/catalogo']);
  }

  irAdminCatalogo(): void {
    this.router.navigate(['/admin/catalogo']);
  }
}