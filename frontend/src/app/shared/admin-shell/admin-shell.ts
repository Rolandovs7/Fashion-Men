import { Component, Input, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink, RouterLinkActive } from '@angular/router';
import { AuthService, Usuario } from '../../core/services/auth.service';

interface EnlaceAdmin {
  ruta: string;
  etiqueta: string;
  icono: string;
}

interface GrupoAdmin {
  titulo: string;
  enlaces: EnlaceAdmin[];
}

@Component({
  selector: 'app-admin-shell',
  standalone: true,
  imports: [CommonModule, RouterLink, RouterLinkActive],
  templateUrl: './admin-shell.html'
})
export class AdminShellComponent implements OnInit {
  /** Título de la pantalla actual, mostrado en la barra superior */
  @Input() titulo = 'Panel de Administración';

  private authService = inject(AuthService);
  private router = inject(Router);

  usuario: Usuario | null = null;
  menuMovilAbierto = false;

  grupos: GrupoAdmin[] = [
    {
      titulo: 'Catálogo',
      enlaces: [
        { ruta: '/admin/catalogo', etiqueta: 'Categorías, productos y variantes', icono: '🗂️' },
        { ruta: '/admin/inventario', etiqueta: 'Inventario', icono: '📊' },
      ]
    },
    {
      titulo: 'Ventas',
      enlaces: [
        { ruta: '/admin/punto-venta', etiqueta: 'Punto de Venta', icono: '🧾' },
        { ruta: '/admin/operaciones', etiqueta: 'Pedidos y Reservas', icono: '📦' },
      ]
    },
    {
      titulo: 'Configuración',
      enlaces: [
        { ruta: '/usuarios', etiqueta: 'Usuarios', icono: '👤' },
        { ruta: '/permisos', etiqueta: 'Permisos', icono: '🔒' },
        { ruta: '/admin/configuracion', etiqueta: 'Roles y Tipos de Pago', icono: '⚙️' },
      ]
    }
  ];

  ngOnInit(): void {
    this.authService.obtenerUsuarioActual().subscribe({
      next: (usuario) => (this.usuario = usuario),
      error: () => {}
    });
  }

  irATienda(): void {
    this.router.navigate(['/catalogo']);
  }

  cerrarSesion(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }

  alternarMenuMovil(): void {
    this.menuMovilAbierto = !this.menuMovilAbierto;
  }

  cerrarMenuMovil(): void {
    this.menuMovilAbierto = false;
  }
}
