import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink, RouterLinkActive } from '@angular/router';
import { AuthService, Usuario } from '../../core/services/auth.service';
import { CarritoService } from '../../core/services/carrito.service';

@Component({
  selector: 'app-header',
  standalone: true,
  imports: [CommonModule, RouterLink, RouterLinkActive],
  templateUrl: './header.html'
})
export class HeaderComponent implements OnInit {
  private authService = inject(AuthService);
  private carritoService = inject(CarritoService);
  private router = inject(Router);

  usuario: Usuario | null = null;
  totalCarrito$ = this.carritoService.contador$;

  ngOnInit(): void {
    if (this.authService.estaAutenticado()) {
      this.authService.obtenerUsuarioActual().subscribe({
        next: (usuario) => (this.usuario = usuario)
      });

      this.carritoService.obtener().subscribe({
        error: () => {} // silencioso: si falla, el badge simplemente queda en 0
      });
    }
  }

  esAdministrador(): boolean {
    return this.usuario?.rol === 'administrador';
  }

  cerrarSesion(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}
