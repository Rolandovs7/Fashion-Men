import { Component, OnInit, OnDestroy, AfterViewInit, inject, ChangeDetectorRef, ElementRef, ViewChild, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { forkJoin } from 'rxjs';
import { ProductosService, Producto } from '../../core/services/productos.service';
import { CategoriasService, Categoria } from '../../core/services/categorias.service';
import { AuthService } from '../../core/services/auth.service';
import { IaService, ProductoSugerido } from '../../core/services/ia.service';
import { VariantesService, Variante, Talla, Color } from '../../core/services/variantes.service';
import { HeaderComponent } from '../../shared/header/header';
import {
  AlertComponent,
  BadgeComponent,
  ButtonComponent,
  EmptyStateComponent,
  InputComponent,
  ModalComponent,
  OpcionSelect,
  PriceComponent,
  SelectComponent,
  SkeletonComponent,
  ToastService
} from '../../shared/ui';

@Component({
  selector: 'app-catalogo',
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    HeaderComponent,
    AlertComponent,
    BadgeComponent,
    ButtonComponent,
    EmptyStateComponent,
    InputComponent,
    ModalComponent,
    PriceComponent,
    SelectComponent,
    SkeletonComponent
  ],
  templateUrl: './catalogo.html',
  styleUrl: './catalogo.css'
})
export class Catalogo implements OnInit, AfterViewInit, OnDestroy {
  private productosService = inject(ProductosService);
  private categoriasService = inject(CategoriasService);
  private authService = inject(AuthService);
  private iaService = inject(IaService);
  private variantesService = inject(VariantesService);
  private toastService = inject(ToastService);
  private router = inject(Router);
  private cdr = inject(ChangeDetectorRef);

  readonly paginaTamano = 8;

  productos: Producto[] = [];
  categorias: Categoria[] = [];
  recomendaciones: ProductoSugerido[] = [];

  busqueda = '';
  categoriaSeleccionada = '';
  filtroTalla = '';
  filtroColor = '';
  orden = '';

  paginaActual = 1;
  cargando = false;
  cargandoVariantes = false;
  error = '';
  filtrosAbiertos = false;

  tallas: Talla[] = [];
  colores: Color[] = [];
  private variantesMap = new Map<number, Variante[]>();

  deseos = new Set<number>();
  private idsNuevos = new Set<number>();

  private acentos = [
    'from-neutral-800 to-neutral-950',
    'from-amber-900/60 to-neutral-950',
    'from-stone-800 to-neutral-950',
    'from-zinc-800 to-neutral-950'
  ];

  // ── Sticky manual por JS ──────────────────────────────────────
  @ViewChild('filtrosAnchor', { static: false }) filtrosAnchor?: ElementRef<HTMLElement>;
  @ViewChild('filtrosBar', { static: false }) filtrosBar?: ElementRef<HTMLElement>;

  // Altura del app-header en px. Ajusta este valor a la altura real de tu header.
  readonly OFFSET_HEADER = 76;

  filtrosFijo = false;
  filtrosAltoPlaceholder = 0;
  containerLeft = 0;
  containerWidth = 0;

  private anchorTop = 0;
  private scrollHandler = () => this.onScrollFiltros();

  ngOnInit(): void {
    this.cargarDatos();
    this.cargarRecomendaciones();
    this.cargarCatalogoTallasYColores();
  }

  ngAfterViewInit(): void {
    setTimeout(() => this.medirTodo(), 0);
    window.addEventListener('scroll', this.scrollHandler, { passive: true });
  }

  ngOnDestroy(): void {
    window.removeEventListener('scroll', this.scrollHandler);
  }

  @HostListener('window:resize')
  onResize(): void {
    this.medirTodo();
  }

  private medirTodo(): void {
    if (!this.filtrosAnchor) return;
    const anchorEl = this.filtrosAnchor.nativeElement;
    const rect = anchorEl.getBoundingClientRect();

    this.anchorTop = rect.top + window.scrollY;
    this.containerLeft = rect.left;
    this.containerWidth = rect.width;

    if (this.filtrosBar) {
      this.filtrosAltoPlaceholder = this.filtrosBar.nativeElement.offsetHeight;
    }
    this.onScrollFiltros();
    this.cdr.detectChanges();
  }

  private onScrollFiltros(): void {
    const debeEstarFijo = window.scrollY + this.OFFSET_HEADER >= this.anchorTop;
    if (debeEstarFijo !== this.filtrosFijo) {
      this.filtrosFijo = debeEstarFijo;
      this.cdr.detectChanges();
    }
  }
  // ── Fin lógica sticky manual ──────────────────────────────────

  cargarDatos(): void {
    this.cargando = true;
    this.error = '';

    this.categoriasService.listar(true).subscribe({
      next: (categorias) => {
        this.categorias = categorias;
        this.cdr.detectChanges();
      },
      error: () => {}
    });

    this.productosService.listar().subscribe({
      next: (productos) => {
        this.productos = productos.filter(p => p.activo);
        this.idsNuevos = new Set(
          [...this.productos].sort((a, b) => b.id - a.id).slice(0, 6).map(p => p.id)
        );
        this.cargando = false;
        this.cdr.detectChanges();
        setTimeout(() => this.medirTodo(), 0);
      },
      error: () => {
        this.error = 'No se pudo cargar el catálogo. Intenta nuevamente más tarde.';
        this.cargando = false;
        this.cdr.detectChanges();
      }
    });
  }

  cargarCatalogoTallasYColores(): void {
    this.variantesService.listarTallas().subscribe({
      next: (tallas) => {
        this.tallas = tallas.filter(t => t.activo);
        this.cdr.detectChanges();
      },
      error: () => {}
    });

    this.variantesService.listarColores().subscribe({
      next: (colores) => {
        this.colores = colores.filter(c => c.activo);
        this.cdr.detectChanges();
      },
      error: () => {}
    });
  }

  cargarRecomendaciones(): void {
    if (!this.authService.estaAutenticado()) return;

    this.iaService.recomendar({ limite: 3 }).subscribe({
      next: (resp) => {
        this.recomendaciones = resp.recomendaciones;
        this.cdr.detectChanges();
        setTimeout(() => this.medirTodo(), 0);
      },
      error: () => {
        this.recomendaciones = [];
      }
    });
  }

  get opcionesCategoria(): OpcionSelect[] {
    return this.categorias.map(c => ({ valor: String(c.id), etiqueta: c.nombre }));
  }

  get opcionesTallas(): OpcionSelect[] {
    return this.tallas.map(t => ({ valor: t.nombre, etiqueta: t.nombre }));
  }

  get opcionesColores(): OpcionSelect[] {
    return this.colores.map(c => ({ valor: c.nombre, etiqueta: c.nombre }));
  }

  readonly opcionesOrden: OpcionSelect[] = [
    { valor: 'precio-asc', etiqueta: 'Precio: menor a mayor' },
    { valor: 'precio-desc', etiqueta: 'Precio: mayor a menor' },
    { valor: 'nombre', etiqueta: 'Nombre: A–Z' },
    { valor: 'novedades', etiqueta: 'Novedades primero' }
  ];

  get filtrosActivos(): boolean {
    return !!(this.busqueda.trim() || this.categoriaSeleccionada || this.filtroTalla || this.filtroColor);
  }

  get chips(): { tipo: 'busqueda' | 'categoria' | 'talla' | 'color'; etiqueta: string }[] {
    const lista: { tipo: 'busqueda' | 'categoria' | 'talla' | 'color'; etiqueta: string }[] = [];
    if (this.busqueda.trim()) lista.push({ tipo: 'busqueda', etiqueta: `"${this.busqueda.trim()}"` });
    if (this.categoriaSeleccionada) {
      lista.push({ tipo: 'categoria', etiqueta: this.nombreCategoria(Number(this.categoriaSeleccionada)) });
    }
    if (this.filtroTalla) lista.push({ tipo: 'talla', etiqueta: `Talla ${this.filtroTalla}` });
    if (this.filtroColor) lista.push({ tipo: 'color', etiqueta: `Color ${this.filtroColor}` });
    return lista;
  }

  quitarChip(tipo: 'busqueda' | 'categoria' | 'talla' | 'color'): void {
    switch (tipo) {
      case 'busqueda': this.busqueda = ''; break;
      case 'categoria': this.categoriaSeleccionada = ''; break;
      case 'talla': this.filtroTalla = ''; break;
      case 'color': this.filtroColor = ''; break;
    }
    this.paginaActual = 1;
  }

  limpiarFiltros(): void {
    this.busqueda = '';
    this.categoriaSeleccionada = '';
    this.filtroTalla = '';
    this.filtroColor = '';
    this.orden = '';
    this.paginaActual = 1;
  }

  abrirFiltros(): void {
    this.filtrosAbiertos = true;
  }

  cerrarFiltros(): void {
    this.filtrosAbiertos = false;
  }

  cambioBusqueda(): void {
    this.paginaActual = 1;
  }

  cambioCategoria(): void {
    this.paginaActual = 1;
  }

  cambioTalla(): void {
    this.paginaActual = 1;
    this.cargarVariantesSiFalta();
  }

  cambioColor(): void {
    this.paginaActual = 1;
    this.cargarVariantesSiFalta();
  }

  cambioOrden(): void {
    this.paginaActual = 1;
  }

  private cargarVariantesSiFalta(): void {
    if ((!this.filtroTalla && !this.filtroColor) || this.cargandoVariantes) return;

    const pendientes = this.productos.filter(p => !this.variantesMap.has(p.id)).map(p => p.id);
    if (pendientes.length === 0) return;

    this.cargandoVariantes = true;
    forkJoin(pendientes.map(id => this.variantesService.listarPorProducto(id))).subscribe({
      next: (listas) => {
        listas.forEach((variantes, i) => this.variantesMap.set(pendientes[i], variantes));
        this.cargandoVariantes = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.cargandoVariantes = false;
        this.filtroTalla = '';
        this.filtroColor = '';
        this.toastService.error('No se pudieron aplicar los filtros de talla y color.');
        this.cdr.detectChanges();
      }
    });
  }

  get productosFiltrados(): Producto[] {
    const filtrados = this.productos.filter(p => {
      const coincideCategoria =
        !this.categoriaSeleccionada ||
        String(p.categoria_id) === this.categoriaSeleccionada;

      const coincideBusqueda =
        !this.busqueda.trim() ||
        p.nombre.toLowerCase().includes(this.busqueda.trim().toLowerCase());

      const variantes = this.variantesMap.get(p.id) ?? [];
      const coincideTalla = !this.filtroTalla || variantes.some(v => v.talla_nombre === this.filtroTalla);
      const coincideColor = !this.filtroColor || variantes.some(v => v.color_nombre === this.filtroColor);

      return coincideCategoria && coincideBusqueda && coincideTalla && coincideColor;
    });

    const copia = [...filtrados];
    switch (this.orden) {
      case 'precio-asc': copia.sort((a, b) => a.precio - b.precio); break;
      case 'precio-desc': copia.sort((a, b) => b.precio - a.precio); break;
      case 'nombre': copia.sort((a, b) => a.nombre.localeCompare(b.nombre)); break;
      case 'novedades': copia.sort((a, b) => b.id - a.id); break;
      default: break;
    }
    return copia;
  }

  get totalPaginas(): number {
    return Math.max(1, Math.ceil(this.productosFiltrados.length / this.paginaTamano));
  }

  get productosPaginados(): Producto[] {
    const inicio = (this.paginaActual - 1) * this.paginaTamano;
    return this.productosFiltrados.slice(inicio, inicio + this.paginaTamano);
  }

  get paginasVisibles(): (number | '...')[] {
    const t = this.totalPaginas;
    const p = this.paginaActual;
    if (t <= 7) return Array.from({ length: t }, (_, i) => i + 1);

    const candidatos = new Set([1, t, p - 1, p, p + 1]);
    const ordenados = [...candidatos].filter(n => n >= 1 && n <= t).sort((a, b) => a - b);
    const resultado: (number | '...')[] = [];
    let previo = 0;
    for (const n of ordenados) {
      if (previo && n - previo > 1) resultado.push('...');
      resultado.push(n);
      previo = n;
    }
    return resultado;
  }

  cambiarPagina(pagina: number): void {
    const p = Math.min(Math.max(pagina, 1), this.totalPaginas);
    if (p === this.paginaActual) return;
    this.paginaActual = p;
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  badgeProducto(p: Producto): { etiqueta: string; tipo: 'acento' | 'aviso' } | null {
    if (p.descuento_id) return { etiqueta: 'Oferta', tipo: 'aviso' };
    if (this.idsNuevos.has(p.id)) return { etiqueta: 'Nuevo', tipo: 'acento' };
    return null;
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

  agregarProducto(p: Producto): void {
    this.toastService.info('Elegí talla y color en el detalle para agregar al carrito.');
    this.verProducto(p);
  }

  nombreCategoria(categoriaId: number): string {
    return this.categorias.find(c => c.id === categoriaId)?.nombre ?? 'Sin categoría';
  }

  acentoPara(id: number): string {
    return this.acentos[id % this.acentos.length];
  }

  verProducto(producto: Producto): void {
    this.router.navigate(['/producto', producto.id]);
  }

  verRecomendado(prod: ProductoSugerido): void {
    this.router.navigate(['/producto', prod.id]);
  }

  onImagenError(event: Event, producto: Producto): void {
    const img = event.target as HTMLImageElement;
    img.style.display = 'none';
    producto.imagen_url = null;
    this.cdr.detectChanges();
  }
}