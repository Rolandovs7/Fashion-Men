import { Component, Input, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink, RouterLinkActive } from '@angular/router';
import { AuthService, Usuario } from '../../core/services/auth.service';
import { ButtonComponent } from '../ui';

interface EnlaceAdmin {
  ruta: string;
  etiqueta: string;
  icono: string;
  soloSuperAdmin?: boolean;
  soloTienda?: boolean; // ocultar para superadmin (menús operativos de tienda)
}

interface GrupoAdmin {
  titulo: string;
  enlaces: EnlaceAdmin[];
  soloSuperAdmin?: boolean;
  soloTienda?: boolean; // ocultar para superadmin
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
      titulo: 'Plataforma',
      soloSuperAdmin: true,
      enlaces: [
        { ruta: '/admin/empresas', etiqueta: 'Empresas (Tenants)', icono: 'empresas', soloSuperAdmin: true },
        { ruta: '/admin/dashboard', etiqueta: 'Dashboard Global', icono: 'reportes', soloSuperAdmin: true },
      ]
    },
    {
      titulo: 'Cuenta',
      enlaces: [
        { ruta: '/admin/suscripcion', etiqueta: 'Mi Suscripción', icono: 'suscripcion' },
      ]
    },
    {
      titulo: 'Catálogo',
      soloTienda: true,
      enlaces: [
        { ruta: '/admin/catalogo', etiqueta: 'Catálogo', icono: 'catalogo', soloTienda: true },
        { ruta: '/admin/inventario', etiqueta: 'Inventario', icono: 'inventario', soloTienda: true },
      ]
    },
    {
      titulo: 'Ventas',
      soloTienda: true,
      enlaces: [
        { ruta: '/admin/punto-venta', etiqueta: 'Punto de Venta', icono: 'venta', soloTienda: true },
        { ruta: '/admin/operaciones', etiqueta: 'Pedidos y Reservas', icono: 'reservas', soloTienda: true },
        { ruta: '/admin/operaciones-pendientes', etiqueta: 'Operaciones Pendientes', icono: 'offline', soloTienda: true },
      ]
    },
    {
      titulo: 'Reportes',
      soloTienda: true,
      enlaces: [
        { ruta: '/admin/dashboard', etiqueta: 'Dashboard', icono: 'reportes', soloTienda: true },
        { ruta: '/admin/reportes', etiqueta: 'Estadísticas', icono: 'reportes', soloTienda: true },
        { ruta: '/admin/asistente-ia', etiqueta: 'Asistente IA', icono: 'ia', soloTienda: true },
      ]
    },
    {
      titulo: 'Configuración',
      soloTienda: true,
      enlaces: [
        { ruta: '/usuarios', etiqueta: 'Usuarios', icono: 'usuarios', soloTienda: true },
        { ruta: '/permisos', etiqueta: 'Permisos', icono: 'permisos', soloTienda: true },
        { ruta: '/admin/configuracion', etiqueta: 'Roles y Tipos de Pago', icono: 'config', soloTienda: true },
      ]
    }
  ];

  ngOnInit(): void {
    try {
      if (this.authService.estaAutenticado()) {
        this.authService.obtenerUsuarioActual().subscribe({
          next: (usuario) => (this.usuario = usuario),
          error: () => {}
        });
      }
    } catch {
      // ignore
    }
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

  get nombreEmpresa(): string {
    const nombre = (this.usuario?.empresa_nombre ?? '').toString().trim();
    return nombre || this.authService.nombreEmpresa();
  }

  inicialesUsuario(): string {
    const nombre = this.usuario?.nombre ?? '';
    const apellido = this.usuario?.apellido ?? '';
    return `${nombre.charAt(0)}${apellido.charAt(0)}`.toUpperCase() || 'U';
  }

  esSuperAdmin(): boolean {
    return this.usuario?.rol === 'superadmin';
  }

  puedeVerGrupo(grupo: GrupoAdmin): boolean {
    if (grupo.soloSuperAdmin && !this.esSuperAdmin()) return false;
    if (grupo.soloTienda && this.esSuperAdmin()) return false;
    return true;
  }

  puedeVerEnlace(enlace: EnlaceAdmin): boolean {
    if (enlace.soloSuperAdmin && !this.esSuperAdmin()) return false;
    if (enlace.soloTienda && this.esSuperAdmin()) return false;
    return true;
  }

  etiquetaRol(): string {
    const rol = this.usuario?.rol;
    if (rol === 'superadmin') return 'SuperAdmin';
    if (rol === 'administrador') return 'Administrador';
    if (rol === 'vendedor') return 'Vendedor';
    if (rol === 'cliente') return 'Cliente';
    return rol ? rol.charAt(0).toUpperCase() + rol.slice(1) : '';
  }
}