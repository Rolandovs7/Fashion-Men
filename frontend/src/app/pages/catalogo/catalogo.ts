import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { ProductosService, Producto } from '../../core/services/productos.service';
import { CategoriasService, Categoria } from '../../core/services/categorias.service';
import { HeaderComponent } from '../../shared/header/header';

@Component({
  selector: 'app-catalogo',
  imports: [CommonModule, FormsModule, HeaderComponent],
  templateUrl: './catalogo.html',
  styleUrl: './catalogo.css'
})
export class Catalogo implements OnInit {
  private productosService = inject(ProductosService);
  private categoriasService = inject(CategoriasService);
  private router = inject(Router);
  private cdr = inject(ChangeDetectorRef);

  productos: Producto[] = [];
  categorias: Categoria[] = [];

  categoriaSeleccionada: number | 'todas' = 'todas';
  busqueda = '';

  cargando = false;
  error = '';

  // Paleta de acentos para las tarjetas placeholder (sin fotos en el catálogo aún)
  private acentos = [
    'from-neutral-800 to-neutral-950',
    'from-amber-900/60 to-neutral-950',
    'from-stone-800 to-neutral-950',
    'from-zinc-800 to-neutral-950'
  ];

  ngOnInit(): void {
    this.cargarDatos();
  }

  cargarDatos(): void {
    this.cargando = true;
    this.error = '';

    this.categoriasService.listar(true).subscribe({
      next: (categorias) => {
        this.categorias = categorias;
        this.cdr.detectChanges();
      },
      error: () => {
        // Si no hay categorías, el filtro simplemente queda vacío
      }
    });

    this.productosService.listar().subscribe({
      next: (productos) => {
        this.productos = productos.filter(p => p.activo);
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'No se pudo cargar el catálogo. Intenta nuevamente más tarde.';
        this.cargando = false;
      }
    });
  }

  get productosFiltrados(): Producto[] {
    return this.productos.filter(p => {
      const coincideCategoria =
        this.categoriaSeleccionada === 'todas' ||
        p.categoria_id === this.categoriaSeleccionada;

      const coincideBusqueda =
        !this.busqueda.trim() ||
        p.nombre.toLowerCase().includes(this.busqueda.trim().toLowerCase());

      return coincideCategoria && coincideBusqueda;
    });
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

  /**
   * Fallback si una imagen no carga: reemplaza el src por vacío
   * para que el @else del template muestre el placeholder SVG.
   */
  onImagenError(event: Event, producto: Producto): void {
    const img = event.target as HTMLImageElement;
    img.style.display = 'none';
    producto.imagen_url = null;
    this.cdr.detectChanges();
  }
}
