import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { ProductosService, Producto } from '../../core/services/productos.service';
import { CategoriasService, Categoria } from '../../core/services/categorias.service';
import { VariantesService, Variante } from '../../core/services/variantes.service';
import { CarritoService } from '../../core/services/carrito.service';
import { DescuentosService, Descuento } from '../../core/services/descuentos.service';
import { IaService, ProductoSugerido } from '../../core/services/ia.service';
import { AuthService } from '../../core/services/auth.service';
import { HeaderComponent } from '../../shared/header/header';
import {
  ButtonComponent,
  AlertComponent,
  BadgeComponent,
  PriceComponent,
  SkeletonComponent,
  EmptyStateComponent,
  FooterComponent,
  ToastService
} from '../../shared/ui';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU25 - Consultar Disponibilidad
// RF: RF08 - El cliente deberá poder consultar disponibilidad por sucursal
// CAPA: Angular | BACKEND: GET /api/variantes/producto/{id} (stock_disponible)
// ============================================================
@Component({
  selector: 'app-producto-detalle',
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    HeaderComponent,
    ButtonComponent,
    AlertComponent,
    BadgeComponent,
    PriceComponent,
    SkeletonComponent,
    EmptyStateComponent,
    FooterComponent
  ],
  templateUrl: './producto-detalle.html',
  styleUrl: './producto-detalle.css'
})
export class ProductoDetalle implements OnInit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private productosService = inject(ProductosService);
  private categoriasService = inject(CategoriasService);
  private variantesService = inject(VariantesService);
  private carritoService = inject(CarritoService);
  private descuentosService = inject(DescuentosService);
  private iaService = inject(IaService);
  private authService = inject(AuthService);
  private toastService = inject(ToastService);
  private cdr = inject(ChangeDetectorRef);

  producto: Producto | null = null;
  categoria: Categoria | null = null;
  variantes: Variante[] = [];

  tallaSeleccionada: string | null = null;
  colorSeleccionado: { id: number; nombre: string; codigoHex: string | null; imagenUrl: string | null } | null = null;
  cantidad = 1;

  relacionados: Producto[] = [];
  recomendaciones: ProductoSugerido[] = [];
  descuento: Descuento | null = null;

  tabActivo: 'descripcion' | 'especificaciones' | 'cuidados' = 'descripcion';
  descripcionExpandida = false;
  deseado = false;

  cargando = true;
  agregando = false;
  error = '';
  mensaje = '';

  private idsNuevos = new Set<number>();
  private colorImgFallida = new Set<number>();
  private acentos = [
    'from-neutral-800 to-neutral-950',
    'from-amber-900/60 to-neutral-950',
    'from-stone-800 to-neutral-950',
    'from-zinc-800 to-neutral-950'
  ];

  ngOnInit(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    if (!id) {
      this.router.navigate(['/catalogo']);
      return;
    }
    this.cargarProducto(id);
  }

  cargarProducto(id: number): void {
    this.cargando = true;
    this.error = '';

    this.productosService.obtener(id).subscribe({
      next: (producto) => {
        this.producto = producto;

        this.categoriasService.listar(false).subscribe({
          next: (categorias) => {
            this.categoria = categorias.find(c => c.id === producto.categoria_id) ?? null;
            this.cdr.detectChanges();
          }
        });

        this.variantesService.listarPorProducto(id).subscribe({
          next: (variantes) => {
            this.variantes = variantes;
            const inicial = variantes.find(v => v.stock_disponible > 0) ?? variantes[0] ?? null;
            if (inicial) {
              this.tallaSeleccionada = inicial.talla_nombre;
              this.colorSeleccionado = {
                id: inicial.color_id,
                nombre: inicial.color_nombre,
                codigoHex: inicial.color_codigo_hex ?? null,
                imagenUrl: inicial.color_imagen_url ?? null
              };
            }
            this.cargando = false;
            this.cdr.detectChanges();
          },
          error: () => {
            this.cargando = false;
            this.cdr.detectChanges();
          }
        });

        this.cargarDescuento(producto);
        this.cargarRelacionados(id, producto);
        this.cargarRecomendaciones(producto);
      },
      error: () => {
        this.error = 'No se encontró el producto solicitado.';
        this.cargando = false;
        this.cdr.detectChanges();
      }
    });
  }

  reintentar(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    if (id) {
      this.cargarProducto(id);
    }
  }

  cargarDescuento(producto: Producto): void {
    if (!producto.descuento_id) return;
    this.descuentosService.listar(true).subscribe({
      next: (lista) => {
        this.descuento = lista.find(d => d.id === producto.descuento_id) ?? null;
        this.cdr.detectChanges();
      },
      error: () => {}
    });
  }

  cargarRelacionados(id: number, producto: Producto): void {
    this.productosService.listar().subscribe({
      next: (productos) => {
        const activos = productos.filter(p => p.activo && p.id !== id);
        this.idsNuevos = new Set(
          [...activos].sort((a, b) => b.id - a.id).slice(0, 6).map(p => p.id)
        );
        const mismaCategoria = activos.filter(p => p.categoria_id === producto.categoria_id);
        const otras = activos.filter(p => p.categoria_id !== producto.categoria_id);
        this.relacionados = [...mismaCategoria, ...otras].slice(0, 4);
        this.cdr.detectChanges();
      },
      error: () => {
        this.relacionados = [];
      }
    });
  }

  cargarRecomendaciones(producto: Producto): void {
    if (!this.authService.estaAutenticado()) return;
    this.iaService.recomendar({ categoria_id: producto.categoria_id, limite: 3 }).subscribe({
      next: (res) => {
        this.recomendaciones = res.recomendaciones;
        this.cdr.detectChanges();
      },
      error: () => {
        this.recomendaciones = [];
      }
    });
  }

  tallasUnicas(): string[] {
    return [...new Set(this.variantes.map(v => v.talla_nombre))];
  }

  /** Colores únicos del producto (sin repetir por talla). */
  coloresUnicos(): Variante[] {
    const vistos = new Map<number, Variante>();
    for (const v of this.variantes) {
      if (!vistos.has(v.color_id)) {
        vistos.set(v.color_id, v);
      }
    }
    return [...vistos.values()];
  }

  seleccionarTalla(talla: string): void {
    this.tallaSeleccionada = talla;
    this.mensaje = '';
    this.error = '';
  }

  seleccionarColor(color: Variante): void {
    this.colorSeleccionado = {
      id: color.color_id,
      nombre: color.color_nombre,
      codigoHex: color.color_codigo_hex ?? null,
      imagenUrl: color.color_imagen_url ?? null
    };
    this.mensaje = '';
    this.error = '';
  }

  /** Variante concreta (talla + color) seleccionada en este momento. */
  get varianteActual(): Variante | null {
    if (!this.tallaSeleccionada || !this.colorSeleccionado) return null;
    return this.variantes.find(v =>
      v.talla_nombre === this.tallaSeleccionada &&
      v.color_id === this.colorSeleccionado!.id
    ) ?? null;
  }

  /** Nombre visible: el de la variante si está definido, si no el del producto. */
  get nombreTitulo(): string {
    const nombreVariante = this.varianteActual?.nombre_variante?.trim();
    return nombreVariante || this.producto?.nombre || '';
  }

  incrementar(): void {
    if (this.stockDisponible > 0 && this.cantidad < this.stockDisponible) {
      this.cantidad++;
      this.error = '';
    }
  }

  decrementar(): void {
    if (this.cantidad > 1) {
      this.cantidad--;
      this.error = '';
    }
  }

  toggleDeseo(): void {
    this.deseado = !this.deseado;
  }

  get stockDisponible(): number {
    return this.varianteActual?.stock_disponible ?? 0;
  }

  get tieneStock(): boolean {
    const variante = this.varianteActual;
    return variante != null && variante.stock_disponible > 0;
  }

  /** Imagen principal: la del color seleccionado, o la genérica del producto. */
  get imagenPrincipal(): string | null {
    const color = this.colorSeleccionado;
    const colorUrl = color && !this.colorImgFallida.has(color.id) ? color.imagenUrl : null;
    return this.normalizarImagen(colorUrl ?? this.producto?.imagen_url ?? null);
  }

  private normalizarImagen(url: string | null): string | null {
    if (!url) return null;
    if (url.startsWith('http')) return url;
    return url.startsWith('/') ? url : '/' + url;
  }

  get tieneDescuento(): boolean {
    return this.descuento != null && this.descuento.porcentaje > 0;
  }

  get precioConDescuento(): number {
    if (!this.descuento || this.descuento.porcentaje <= 0) return this.producto?.precio ?? 0;
    const bruto = this.producto!.precio * (100 - this.descuento.porcentaje) / 100;
    return Math.round(bruto * 100) / 100;
  }

  get descripcionCorta(): string {
    const texto = (this.producto?.descripcion ?? '').trim();
    if (texto.length <= 150) return texto;
    return texto.slice(0, 150).replace(/\s+\S*$/, '') + '…';
  }

  get descripcionLarga(): boolean {
    return ((this.producto?.descripcion ?? '').trim().length) > 150;
  }

  badgeProducto(): { etiqueta: string; tipo: 'acento' | 'aviso' } | null {
    if (!this.producto) return null;
    if (this.producto.descuento_id != null) return { etiqueta: 'Oferta', tipo: 'acento' };
    if (this.idsNuevos.has(this.producto.id)) return { etiqueta: 'Nuevo', tipo: 'aviso' };
    return null;
  }

  acentoPara(id: number): string {
    return this.acentos[id % this.acentos.length];
  }

  get codigo(): string {
    return '#' + String(this.producto?.id ?? '').padStart(4, '0');
  }

  seleccionarTab(tab: 'descripcion' | 'especificaciones' | 'cuidados'): void {
    this.tabActivo = tab;
  }

  agregarAlCarrito(): void {
    const variante = this.varianteActual;
    if (!variante) {
      this.error = 'Selecciona una talla y color disponibles.';
      return;
    }

    if (this.cantidad < 1 || this.cantidad > variante.stock_disponible) {
      this.error = `Elige una cantidad entre 1 y ${variante.stock_disponible}.`;
      return;
    }

    this.agregando = true;
    this.error = '';
    this.mensaje = '';

    this.carritoService.agregarItem(variante.id, this.cantidad).subscribe({
      next: () => {
        this.agregando = false;
        this.mensaje = 'Prenda agregada al carrito.';
        this.toastService.exito('Prenda agregada al carrito.');
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.agregando = false;
        if (error.status === 401) {
          this.error = 'Inicia sesión para agregar al carrito.';
        } else {
          this.error = error.error?.detail || 'No se pudo agregar al carrito.';
        }
        this.cdr.detectChanges();
      }
    });
  }

  reservar(): void {
    if (!this.varianteActual) {
      this.toastService.aviso('Primero elegí talla y color.');
      return;
    }
    this.toastService.info('Las reservas se gestionan desde tu cuenta.');
    this.router.navigate(['/reservas']);
  }

  avisarDisponible(): void {
    this.toastService.info('Te avisaremos cuando esta prenda vuelva a estar disponible.');
  }

  irCarrito(): void {
    this.router.navigate(['/carrito']);
  }

  irCatalogo(): void {
    this.router.navigate(['/catalogo']);
  }

  irProducto(id: number): void {
    this.router.navigate(['/producto', id]);
  }

  /**
   * Fallback si la imagen del producto no carga: la oculta y
   * el @else del template muestra el placeholder SVG.
   */
  onImagenError(event: Event): void {
    const img = event.target as HTMLImageElement;
    img.style.display = 'none';
    const color = this.colorSeleccionado;
    if (color && this.colorImgFallida.has(color.id)) {
      // Ya cayó al genérico del producto antes; nada que hacer.
      return;
    }
    if (color && color.imagenUrl) {
      // La imagen del color no carga: se cae al fallback genérico del producto.
      this.colorImgFallida.add(color.id);
    } else if (this.producto) {
      this.producto.imagen_url = null;
    }
    this.cdr.detectChanges();
  }
}