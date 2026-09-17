#!/bin/bash

set -e

echo "🔧 Actualizando configuración de Angular para CU01..."

cat > src/app/app.config.ts <<'EOF'
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';

import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes),
    provideHttpClient()
  ]
};
EOF

cat > src/app/app.routes.ts <<'EOF'
import { Routes } from '@angular/router';
import { Login } from './pages/login/login';
import { Inicio } from './pages/inicio/inicio';

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
    path: 'inicio',
    component: Inicio
  },
  {
    path: '**',
    redirectTo: 'login'
  }
];
EOF

echo "✅ app.config.ts actualizado."
echo "✅ app.routes.ts actualizado."
echo "🚀 CU01 listo para probar."
