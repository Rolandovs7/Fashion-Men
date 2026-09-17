import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { map, catchError, of } from 'rxjs';
import { AuthService } from '../services/auth.service';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU01 - Administrar Inicio de Sesión / CU02 - Administrar Cierre de Sesión
// RF: RF02 - Gestionar usuarios y roles (control de acceso derivado)
// CAPA: Angular (route guards)
// ARCHIVO: core/guards/auth.guard.ts
//
// Antes de esta ronda no existía ningún guard: cualquier usuario podía
// navegar directamente a rutas protegidas escribiendo la URL, sin
// sesión iniciada. authGuard corrige esto para CU01/CU02 exigiendo
// token válido; adminGuard lo extiende para CU04/CU05/CU06 exigiendo
// además rol "administrador" (CU06 tiene Riesgo: CRÍTICO).
// ============================================================

// CU01/CU02 - Requiere sesión iniciada (token presente) para acceder
export const authGuard: CanActivateFn = () => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.estaAutenticado()) {
    return true;
  }

  router.navigate(['/login']);
  return false;
};

// CU04/CU05/CU06 - Requiere sesión iniciada Y rol "administrador"
// Consume GET /api/auth/me para verificar el rol real contra el backend
// (no confía únicamente en datos guardados en el cliente).
export const adminGuard: CanActivateFn = () => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (!authService.estaAutenticado()) {
    router.navigate(['/login']);
    return of(false);
  }

  return authService.obtenerUsuarioActual().pipe(
    map((usuario) => {
      if (usuario.rol === 'administrador') {
        return true;
      }
      router.navigate(['/catalogo']);
      return false;
    }),
    catchError(() => {
      router.navigate(['/login']);
      return of(false);
    })
  );
};
