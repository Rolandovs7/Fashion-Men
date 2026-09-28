// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU14 - Administrar Catálogo (vista pública)
// RF: RF07 - Catálogo web y móvil (landing)
// CAPA: Frontend Angular
// Nota: rediseño visual "Quiet Editorial Luxury" (Fase 2).
// Los datos del home son placeholders de vitrina; la conexión
// a ProductosService/CategoriasService se retoma en la Fase 3.
// ============================================================
import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { HeaderComponent } from '../../shared/header/header';
import { BadgeComponent } from '../../shared/ui/badge/badge';
import { ButtonComponent } from '../../shared/ui/button/button';
import { InputComponent } from '../../shared/ui/input/input';
import { PriceComponent } from '../../shared/ui/price/price';
import { ToastService } from '../../shared/ui/toast/toast.service';

export interface CategoriaVitrina {
  nombre: string;
  etiqueta: string;
  imagen: string;
}

export interface ProductoVitrina {
  id: number;
  nombre: string;
  categoria: string;
  descripcion: string;
  precio: number;
  precioAntes?: number;
  badge: string;
  badgeTipo: 'acento' | 'aviso' | 'neutral';
  imagen: string;
}

export interface SucursalVitrina {
  ciudad: string;
  zona: string;
  direccion: string;
  horario: string;
}

@Component({
  selector: 'app-inicio',
  standalone: true,
  imports: [
    FormsModule,
    HeaderComponent,
    BadgeComponent,
    ButtonComponent,
    InputComponent,
    PriceComponent
  ],
  templateUrl: './inicio.html',
  styleUrl: './inicio.css'
})
export class Inicio {

  private router = inject(Router);
  private toastService = inject(ToastService);

  categorias: CategoriaVitrina[] = [
    { nombre: 'Camisas', etiqueta: 'Telas nobles',   imagen: '/imagenes/camisas/camisa-formal-blanca.jpg' },
    { nombre: 'Chaquetas', etiqueta: 'Corte urbano', imagen: '/imagenes/chaquetas/chaqueta-cuero.jpg' },
    { nombre: 'Pantalones', etiqueta: 'Ajuste perfecto', imagen: '/imagenes/pantalones/pantalon-vestir-negro.jpg' },
    { nombre: 'Accesorios', etiqueta: 'Detalles finos', imagen: '/imagenes/accesorios/cinturon-cuero.jpg' }
  ];

  productos: ProductoVitrina[] = [
    {
      id: 1,
      nombre: 'Camisa Oxford Blanca',
      categoria: 'Camisas',
      descripcion: '100% algodón pima, cuello italiano.',
      precio: 420,
      badge: 'Nuevo',
      badgeTipo: 'acento',
      imagen: '/imagenes/camisas/camisa-formal-blanca.jpg'
    },
    {
      id: 2,
      nombre: 'Blazer Negro Slim',
      categoria: 'Chaquetas',
      descripcion: 'Lana fría, forro de seda.',
      precio: 1250,
      badge: 'Nuevo',
      badgeTipo: 'acento',
      imagen: '/imagenes/chaquetas/chaqueta-deportiva.jpg'
    },
    {
      id: 3,
      nombre: 'Pantalón Chino Beige',
      categoria: 'Pantalones',
      descripcion: 'Corte regular, tiro medio.',
      precio: 380,
      precioAntes: 490,
      badge: 'Oferta',
      badgeTipo: 'aviso',
      imagen: '/imagenes/pantalones/jean-clasico-azul.jpg'
    },
    {
      id: 4,
      nombre: 'Abrigo Lana Merino',
      categoria: 'Abrigos',
      descripcion: 'Edición limitada, 500 unidades.',
      precio: 1890,
      badge: 'Exclusivo',
      badgeTipo: 'neutral',
      imagen: '/imagenes/trajes/traje-completo-gris.jpg'
    }
  ];

  sucursales: SucursalVitrina[] = [
    { ciudad: 'Santa Cruz', zona: 'Equipetrol Norte', direccion: 'Av. San Martín', horario: 'Lun – Sáb · 10:00 – 20:00' },
    { ciudad: 'La Paz', zona: 'Calacoto', direccion: 'Calle 15', horario: 'Lun – Sáb · 10:00 – 19:30' },
    { ciudad: 'Cochabamba', zona: 'Queru Queru', direccion: 'Av. Pando', horario: 'Lun – Sáb · 10:00 – 19:30' }
  ];

  deseos = new Set<number>();
  emailNewsletter = '';

  irA(ruta: string): void {
    this.router.navigate([ruta]);
  }

  esDeseado(id: number): boolean {
    return this.deseos.has(id);
  }

  toggleDeseo(id: number): void {
    if (this.deseos.has(id)) {
      this.deseos.delete(id);
    } else {
      this.deseos.add(id);
    }
  }

  agregarVitrina(p: ProductoVitrina): void {
    this.toastService.exito(`«${p.nombre}» listo para el carrito (demo visual).`);
  }

  suscribirse(): void {
    const email = this.emailNewsletter.trim();
    if (!email || !email.includes('@') || !email.includes('.')) {
      this.toastService.aviso('Ingresá un correo válido para suscribirte.');
      return;
    }
    this.toastService.exito('¡Bienvenido al círculo MenStyle! Te escribiremos pronto.');
    this.emailNewsletter = '';
  }
}