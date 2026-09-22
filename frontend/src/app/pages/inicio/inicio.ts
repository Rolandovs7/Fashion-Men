// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU14 - Administrar Catálogo (vista pública)
// RF: RF07 - Catálogo web y móvil (landing)
// CAPA: Frontend Angular
// ============================================================
import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { HeaderComponent } from '../../shared/header/header';
import { ProductosService, Producto } from '../../core/services/productos.service';
import { CategoriasService, Categoria } from '../../core/services/categorias.service';



@Component({
  selector: 'app-inicio',
  standalone: true,
  imports: [CommonModule, RouterLink, HeaderComponent],
  templateUrl: './inicio.html',
  styleUrl: './inicio.css'
})
export class Inicio implements OnInit {

  private productosService = inject(ProductosService);
  private categoriasService = inject(CategoriasService);
  private cdr = inject(ChangeDetectorRef);

  productos: Producto[] = [];
  categorias: Categoria[] = [];
  cargando = true;

  ngOnInit(): void {
    this.cargarDatos();
  }

  private cargarDatos(): void {
    this.categoriasService.listar(true).subscribe({
      next: (cats) => {
        this.categorias = cats.slice(0, 6);
        this.cdr.detectChanges();
      },
      error: () => {}
    });

    this.productosService.listar().subscribe({
      next: (prods) => {
        this.productos = prods.filter(p => p.activo).slice(0, 8);
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.cargando = false;
        this.cdr.detectChanges();
      }
    });
  }

  /** Devuelve la URL de la imagen del producto (relativa al frontend) */
  urlImagen(p: Producto): string | null {
    if (!p.imagen_url) return null;
    if (p.imagen_url.startsWith('http')) return p.imagen_url;
    // Las imágenes están en frontend/public/imagenes/ → usar ruta relativa
    return p.imagen_url.startsWith('/') ? p.imagen_url : '/' + p.imagen_url;
  }

  /** Icono según categoría */
  iconoCategoria(nombre: string): string {
    const n = nombre.toLowerCase();
    if (n.includes('camisa') || n.includes('camis')) return '👔';
    if (n.includes('pantal')) return '👖';
    if (n.includes('traje') || n.includes('saco')) return '🤵';
    if (n.includes('zapat') || n.includes('calzado')) return '👞';
    if (n.includes('accesor')) return '🕶️';
    if (n.includes('chaqueta') || n.includes('abrigo')) return '🧥';
    return '👕';
  }
}
