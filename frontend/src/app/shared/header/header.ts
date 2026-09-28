import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink, RouterLinkActive } from '@angular/router';
import { AuthService, Usuario } from '../../core/services/auth.service';
import { CarritoService } from '../../core/services/carrito.service';
import { NotificacionesService } from '../../core/services/notificaciones.service';

@Component({
  selector: 'app-header',
  standalone: true,
  imports: [CommonModule, RouterLink, RouterLinkActive],
  templateUrl: './header.html'
})
export class HeaderComponent implements OnInit {
  private authService = inject(AuthService);
  private carritoService = inject(CarritoService);
  private notifService = inject(NotificacionesService);
  private router = inject(Router);

  usuario: Usuario | null = null;
  totalCarrito$ = this.carritoService.contador$;
  noLeidas$ = this.notifService.noLeidas;

  menuAbierto = false;

  ngOnInit(): void {
    if (this.authService.estaAutenticado()) {
      this.authService.obtenerUsuarioActual().subscribe({
        next: (usuario) => {
          this.usuario = usuario;
          this.notifService.refrescarContador();
        }
      });

      this.carritoService.obtener().subscribe({
        error: () => {}
      });
    }
  }

  esAdministrador(): boolean {
    return this.usuario?.rol === 'administrador';
  }

  toggleMenu(): void {
    this.menuAbierto = !this.menuAbierto;
  }

  cerrarMenu(): void {
    this.menuAbierto = false;
  }

  cerrarSesion(): void {
    this.cerrarMenu();
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}
