import { Routes } from '@angular/router';

import { Login } from './pages/login/login';
import { Inicio } from './pages/inicio/inicio';
import { Registro } from './pages/registro/registro';
import { Usuarios } from './pages/usuarios/usuarios';
import { Permisos } from './pages/permisos/permisos';
import { Catalogo } from './pages/catalogo/catalogo';
import { ProductoDetalle } from './pages/producto-detalle/producto-detalle';
import { CarritoPage } from './pages/carrito/carrito';
import { PedidosPage } from './pages/pedidos/pedidos';
import { Checkout } from './pages/checkout/checkout';
import { ReservasPage } from './pages/reservas/reservas';
import { AdminCatalogo } from './pages/admin-catalogo/admin-catalogo';
import { AdminOperaciones } from './pages/admin-operaciones/admin-operaciones';
import { PuntoVenta } from './pages/punto-venta/punto-venta';
import { AdminConfiguracion } from './pages/admin-configuracion/admin-configuracion';
import { AdminInventario } from './pages/admin-inventario/admin-inventario';
import { AdminReportes } from './pages/admin-reportes/admin-reportes';
import { authGuard, adminGuard } from './core/guards/auth.guard';
import { ForgotPassword } from './pages/forgot-password/forgot-password';
import { ResetPassword } from './pages/reset-password/reset-password';
import { NotificacionesPage } from './pages/notificaciones/notificaciones';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU01/CU02 (authGuard) y CU04/CU05/CU06 (adminGuard)
// RF: RF02 - Gestionar usuarios y roles
// CAPA: Angular (routing)
// Rutas de cliente autenticado -> authGuard.
// Rutas de administración (Catálogo/Ventas/Configuración) -> adminGuard.
// 'catalogo' y 'producto/:id' quedan públicas a propósito (RF07:
// el cliente debe poder consultar el catálogo desde web y móvil).
// ============================================================
export const routes: Routes = [
  {
    path: '',
    redirectTo: 'login',
    pathMatch: 'full'
  },
  {
    path: 'login',
    component: Login
  },
  {
    path: 'registro',
    component: Registro
  },
  {
    path: 'forgot-password',
    component: ForgotPassword
  },
  {
    path: 'reset-password',
    component: ResetPassword
  },
  {
    path: 'inicio',
    component: Inicio,
    canActivate: [authGuard]
  },
  {
    path: 'catalogo',
    component: Catalogo
  },
  {
    path: 'producto/:id',
    component: ProductoDetalle
  },
  {
    path: 'carrito',
    component: CarritoPage,
    canActivate: [authGuard]
  },
  {
    path: 'checkout/:pedidoId',
    component: Checkout,
  },
  {
    path: 'pedidos',
    component: PedidosPage,
    canActivate: [authGuard]
  },
  {
    path: 'reservas',
    component: ReservasPage,
    canActivate: [authGuard]
  },
  {
    path: 'notificaciones',
    component: NotificacionesPage,
    canActivate: [authGuard]
  },
  {
    path: 'admin/catalogo',
    component: AdminCatalogo,
    canActivate: [adminGuard]
  },
  {
    path: 'admin/operaciones',
    component: AdminOperaciones,
    canActivate: [adminGuard]
  },
  {
    path: 'admin/punto-venta',
    component: PuntoVenta,
    canActivate: [adminGuard]
  },
  {
    path: 'admin/configuracion',
    component: AdminConfiguracion,
    canActivate: [adminGuard]
  },
  {
    path: 'admin/inventario',
    component: AdminInventario,
    canActivate: [adminGuard]
  },
  {
    path: 'admin/reportes',
    component: AdminReportes,
    canActivate: [adminGuard]
  },
  {
    path: 'usuarios',
    component: Usuarios,
    canActivate: [adminGuard]
  },
  {
    path: 'permisos',
    component: Permisos,
    canActivate: [adminGuard]
  },
  {
    path: '**',
    redirectTo: 'login'
  }
];