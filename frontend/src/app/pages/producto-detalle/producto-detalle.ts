import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { ProductosService, Producto } from '../../core/services/productos.service';
import { CategoriasService, Categoria } from '../../core/services/categorias.service';
import { VariantesService, Variante } from '../../core/services/variantes.service';
import { CarritoService } from '../../core/services/carrito.service';
import { HeaderComponent } from '../../shared/header/header';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU25 - Consultar Disponibilidad
// RF: RF08 - El cliente deberá poder consultar disponibilidad por sucursal
// CAPA: Angular | BACKEND: GET /api/variantes/producto/{id} (stock_disponible)
// ============================================================
@Component({
  selector: 'app-producto-detalle',
  imports: [CommonModule, FormsModule, RouterLink, HeaderComponent],
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
  private cdr = inject(ChangeDetectorRef);

  producto: Producto | null = null;
  categoria: Categoria | null = null;
  variantes: Variante[] = [];

  varianteSeleccionada: Variante | null = null;
  cantidad = 1;

  cargando = true;
  agregando = false;
  error = '';
  mensaje = '';

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
            this.varianteSeleccionada = variantes.find(v => v.stock_disponible > 0) ?? variantes[0] ?? null;
            this.cargando = false;
            this.cdr.detectChanges();
          },
          error: () => {
            this.cargando = false;
            this.cdr.detectChanges();
          }
        });
      },
      error: () => {
        this.error = 'No se encontró el producto solicitado.';
        this.cargando = false;
      }
    });
  }

  tallasUnicas(): string[] {
    return [...new Set(this.variantes.map(v => v.talla_nombre))];
  }

  coloresParaTalla(talla: string): Variante[] {
    return this.variantes.filter(v => v.talla_nombre === talla);
  }

  seleccionarVariante(variante: Variante): void {
    this.varianteSeleccionada = variante;
    this.mensaje = '';
    this.error = '';
  }

  get stockDisponible(): number {
    return this.varianteSeleccionada?.stock_disponible ?? 0;
  }

  agregarAlCarrito(): void {
    if (!this.varianteSeleccionada) {
      this.error = 'Selecciona una talla y color disponibles.';
      return;
    }

    if (this.cantidad < 1 || this.cantidad > this.stockDisponible) {
      this.error = `Elige una cantidad entre 1 y ${this.stockDisponible}.`;
      return;
    }

    this.agregando = true;
    this.error = '';
    this.mensaje = '';

    this.carritoService.agregarItem(this.varianteSeleccionada.id, this.cantidad).subscribe({
      next: () => {
        this.agregando = false;
        this.mensaje = 'Prenda agregada al carrito.';
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

  irCarrito(): void {
    this.router.navigate(['/carrito']);
  }

  /**
   * Fallback si la imagen del producto no carga: la oculta y
   * el @else del template muestra el placeholder SVG.
   */
  onImagenError(event: Event): void {
    const img = event.target as HTMLImageElement;
    img.style.display = 'none';
    if (this.producto) {
      this.producto.imagen_url = null;
    }
    this.cdr.detectChanges();
  }
}
