import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { InventarioService, Inventario } from '../../core/services/inventario.service';
import { SucursalesService, Sucursal } from '../../core/services/sucursales.service';
import { ProductosService, Producto } from '../../core/services/productos.service';
import { VariantesService, Variante } from '../../core/services/variantes.service';
import { AdminShellComponent } from '../../shared/admin-shell/admin-shell';
import {
  ButtonComponent,
  AlertComponent,
  SelectComponent,
  InputComponent,
  EmptyStateComponent,
  SkeletonComponent,
  type OpcionSelect
} from '../../shared/ui';

interface FilaInventario extends Inventario {
  editando?: boolean;
  cantidadEdit?: number;
  reservadaEdit?: number;
}

@Component({
  selector: 'app-admin-inventario',
  imports: [CommonModule, FormsModule, AdminShellComponent, ButtonComponent, AlertComponent, SelectComponent, InputComponent, EmptyStateComponent, SkeletonComponent],
  templateUrl: './admin-inventario.html',
  styleUrl: './admin-inventario.css'
})
export class AdminInventario implements OnInit {
  private inventarioService = inject(InventarioService);
  private sucursalesService = inject(SucursalesService);
  private productosService = inject(ProductosService);
  private variantesService = inject(VariantesService);
  private cdr = inject(ChangeDetectorRef);

  sucursales: Sucursal[] = [];
  productos: Producto[] = [];
  variantesDelProducto: Variante[] = [];
  filas: FilaInventario[] = [];

  sucursalSeleccionadaId: number | null = null;
  productoSeleccionadoId: number | null = null;
  varianteSeleccionadaId: number | null = null;
  cantidadNueva = 0;

  cargando = false;
  guardando = false;
  error = '';
  mensaje = '';

  paginaActual = 0;
  pageSize = 20;
  totalPaginas = 0;
  totalRegistros = 0;

  ngOnInit(): void {
    this.sucursalesService.listar(true).subscribe({
      next: (sucursales) => {
        this.sucursales = sucursales;
        if (sucursales.length > 0) {
          this.sucursalSeleccionadaId = sucursales[0].id;
          this.cargarInventario();
        }
        this.cdr.detectChanges();
      }
    });

    this.productosService.listar().subscribe({
      next: (productos) => {
        this.productos = productos.filter(p => p.activo);
        this.cdr.detectChanges();
      }
    });
  }

  cambiarSucursal(): void {
    this.paginaActual = 0;
    this.cargarInventario();
  }

  cargarInventario(): void {
    if (!this.sucursalSeleccionadaId) return;

    this.cargando = true;
    this.error = '';

    this.inventarioService.listarDetalladoPaginado(
      this.sucursalSeleccionadaId,
      this.paginaActual,
      this.pageSize
    ).subscribe({
      next: (resp) => {
        this.filas = resp.items.map(item => ({ ...item }));
        this.totalRegistros = resp.total;
        this.totalPaginas = resp.total_pages;
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'No se pudo cargar el inventario de esta sucursal.';
        this.cargando = false;
        this.cdr.detectChanges();
      }
    });
  }

  cambiarPagina(p: number): void {
    if (p < 0 || p >= this.totalPaginas) return;
    this.paginaActual = p;
    this.cargarInventario();
  }

  cargarVariantesDelProducto(): void {
    this.varianteSeleccionadaId = null;
    if (!this.productoSeleccionadoId) {
      this.variantesDelProducto = [];
      return;
    }

    this.variantesService.listarPorProducto(this.productoSeleccionadoId).subscribe({
      next: (variantes) => {
        this.variantesDelProducto = variantes;
        this.cdr.detectChanges();
      }
    });
  }

  // ── Opciones para app-select (app-select entrega strings) ──

  get opcionesSucursales(): OpcionSelect[] {
    return this.sucursales.map(s => ({ valor: s.id, etiqueta: `${s.nombre} — ${s.ciudad}` }));
  }

  get opcionesProductos(): OpcionSelect[] {
    return this.productos.map(p => ({ valor: p.id, etiqueta: p.nombre }));
  }

  get opcionesVariantes(): OpcionSelect[] {
    return this.variantesDelProducto.map(v => ({ valor: v.id, etiqueta: `${v.talla_nombre} · ${v.color_nombre}` }));
  }

  onSucursalCambiada(valor: string): void {
    this.sucursalSeleccionadaId = valor === '' ? null : Number(valor);
    this.cambiarSucursal();
  }

  onProductoSeleccionado(valor: string): void {
    this.productoSeleccionadoId = valor === '' ? null : Number(valor);
    this.cargarVariantesDelProducto();
  }

  onVarianteSeleccionada(valor: string): void {
    this.varianteSeleccionadaId = valor === '' ? null : Number(valor);
  }

  onCantidadNueva(valor: string): void {
    this.cantidadNueva = valor === '' ? 0 : Math.max(0, Number(valor) || 0);
  }

  agregarStock(): void {
    if (!this.sucursalSeleccionadaId || !this.varianteSeleccionadaId || this.cantidadNueva < 0) {
      this.error = 'Selecciona producto, variante y una cantidad válida.';
      return;
    }

    this.guardando = true;
    this.error = '';

    this.inventarioService.crear({
      variante_id: this.varianteSeleccionadaId,
      sucursal_id: this.sucursalSeleccionadaId,
      cantidad: this.cantidadNueva
    }).subscribe({
      next: () => {
        this.guardando = false;
        this.mensaje = 'Stock registrado correctamente.';
        this.productoSeleccionadoId = null;
        this.varianteSeleccionadaId = null;
        this.cantidadNueva = 0;
        this.paginaActual = 0;
        this.cargarInventario();
      },
      error: (error) => {
        this.guardando = false;
        this.error = error.error?.detail || 'No se pudo registrar el stock.';
        this.cdr.detectChanges();
      }
    });
  }

  editarFila(fila: FilaInventario): void {
    fila.editando = true;
    fila.cantidadEdit = fila.cantidad;
    fila.reservadaEdit = fila.cantidad_reservada;
  }

  cancelarEdicion(fila: FilaInventario): void {
    fila.editando = false;
  }

  guardarFila(fila: FilaInventario): void {
    if (fila.cantidadEdit == null || fila.reservadaEdit == null || fila.reservadaEdit > fila.cantidadEdit) {
      this.error = 'La cantidad reservada no puede ser mayor que la cantidad total.';
      return;
    }

    this.inventarioService.actualizar(fila.id, {
      cantidad: fila.cantidadEdit,
      cantidad_reservada: fila.reservadaEdit
    }).subscribe({
      next: (actualizado) => {
        fila.cantidad = actualizado.cantidad;
        fila.cantidad_reservada = actualizado.cantidad_reservada;
        fila.editando = false;
        this.mensaje = 'Inventario actualizado correctamente.';
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.error = error.error?.detail || 'No se pudo actualizar el inventario.';
        this.cdr.detectChanges();
      }
    });
  }

  eliminarFila(fila: FilaInventario): void {
    if (!confirm('¿Eliminar este registro de inventario?')) return;

    this.inventarioService.eliminar(fila.id).subscribe({
      next: () => {
        this.mensaje = 'Registro de inventario eliminado.';
        this.cargarInventario();
      },
      error: () => {
        this.error = 'No se pudo eliminar el registro.';
        this.cdr.detectChanges();
      }
    });
  }
}
