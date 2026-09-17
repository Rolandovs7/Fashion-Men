import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { InventarioService, Inventario } from '../../core/services/inventario.service';
import { SucursalesService, Sucursal } from '../../core/services/sucursales.service';
import { ProductosService, Producto } from '../../core/services/productos.service';
import { VariantesService, Variante } from '../../core/services/variantes.service';
import { AdminShellComponent } from '../../shared/admin-shell/admin-shell';

interface FilaInventario {
  inventario: Inventario;
  variante?: Variante;
  producto?: Producto;
  editando?: boolean;
  cantidadEdit?: number;
  reservadaEdit?: number;
}

@Component({
  selector: 'app-admin-inventario',
  imports: [CommonModule, FormsModule, AdminShellComponent],
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
    this.cargarInventario();
  }

  cargarInventario(): void {
    if (!this.sucursalSeleccionadaId) return;

    this.cargando = true;
    this.error = '';

    this.inventarioService.listar(this.sucursalSeleccionadaId).subscribe({
      next: (inventarios) => this.resolverFilas(inventarios),
      error: () => {
        this.error = 'No se pudo cargar el inventario de esta sucursal.';
        this.cargando = false;
        this.cdr.detectChanges();
      }
    });
  }

  private resolverFilas(inventarios: Inventario[]): void {
    if (inventarios.length === 0) {
      this.filas = [];
      this.cargando = false;
      this.cdr.detectChanges();
      return;
    }

    const solicitudesVariantes = inventarios.map((inv) =>
      this.variantesService.obtenerPorId(inv.variante_id).pipe(catchError(() => of(null)))
    );

    forkJoin(solicitudesVariantes).subscribe((variantes) => {
      const productoIds = [...new Set(variantes.filter((v): v is Variante => !!v).map(v => v.producto_id))];

      if (productoIds.length === 0) {
        this.filas = inventarios.map(inv => ({ inventario: inv }));
        this.cargando = false;
        this.cdr.detectChanges();
        return;
      }

      const solicitudesProductos = productoIds.map((id) =>
        this.productosService.obtener(id).pipe(catchError(() => of(null)))
      );

      forkJoin(solicitudesProductos).subscribe((productos) => {
        const mapaProductos = new Map<number, Producto>();
        productos.forEach(p => { if (p) mapaProductos.set(p.id, p); });

        this.filas = inventarios.map((inv, i) => {
          const variante = variantes[i] ?? undefined;
          const producto = variante ? mapaProductos.get(variante.producto_id) : undefined;
          return { inventario: inv, variante, producto };
        });

        this.cargando = false;
        this.cdr.detectChanges();
      });
    });
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
    fila.cantidadEdit = fila.inventario.cantidad;
    fila.reservadaEdit = fila.inventario.cantidad_reservada;
  }

  cancelarEdicion(fila: FilaInventario): void {
    fila.editando = false;
  }

  guardarFila(fila: FilaInventario): void {
    if (fila.cantidadEdit == null || fila.reservadaEdit == null || fila.reservadaEdit > fila.cantidadEdit) {
      this.error = 'La cantidad reservada no puede ser mayor que la cantidad total.';
      return;
    }

    this.inventarioService.actualizar(fila.inventario.id, {
      cantidad: fila.cantidadEdit,
      cantidad_reservada: fila.reservadaEdit
    }).subscribe({
      next: (actualizado) => {
        fila.inventario = actualizado;
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

    this.inventarioService.eliminar(fila.inventario.id).subscribe({
      next: () => {
        this.filas = this.filas.filter(f => f !== fila);
        this.mensaje = 'Registro de inventario eliminado.';
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'No se pudo eliminar el registro.';
        this.cdr.detectChanges();
      }
    });
  }
}
