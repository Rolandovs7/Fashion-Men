import { Component, Input, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink, RouterLinkActive } from '@angular/router';
import { AuthService, Usuario } from '../../core/services/auth.service';
import { ButtonComponent } from '../ui';

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
  imports: [CommonModule, RouterLink, RouterLinkActive, ButtonComponent],
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
        { ruta: '/admin/catalogo', etiqueta: 'Catálogo', icono: 'catalogo' },
        { ruta: '/admin/inventario', etiqueta: 'Inventario', icono: 'inventario' },
      ]
    },
    {
      titulo: 'Ventas',
      enlaces: [
        { ruta: '/admin/punto-venta', etiqueta: 'Punto de Venta', icono: 'venta' },
        { ruta: '/admin/operaciones', etiqueta: 'Pedidos y Reservas', icono: 'reservas' },
      ]
    },
    {
      titulo: 'Reportes',
      enlaces: [
        { ruta: '/admin/reportes', etiqueta: 'Estadísticas', icono: 'reportes' },
      ]
    },
    {
      titulo: 'Configuración',
      enlaces: [
        { ruta: '/usuarios', etiqueta: 'Usuarios', icono: 'usuarios' },
        { ruta: '/permisos', etiqueta: 'Permisos', icono: 'permisos' },
        { ruta: '/admin/configuracion', etiqueta: 'Roles y Tipos de Pago', icono: 'config' },
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

  inicialesUsuario(): string {
    const nombre = this.usuario?.nombre ?? '';
    const apellido = this.usuario?.apellido ?? '';
    return `${nombre.charAt(0)}${apellido.charAt(0)}`.toUpperCase() || 'U';
  }
}