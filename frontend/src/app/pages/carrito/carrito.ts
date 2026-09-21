import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { CarritoService, Carrito, DetalleCarrito } from '../../core/services/carrito.service';
import { ProductosService, Producto } from '../../core/services/productos.service';
import { VariantesService, Variante } from '../../core/services/variantes.service';
import { SucursalesService, Sucursal } from '../../core/services/sucursales.service';
import { PedidosService } from '../../core/services/pedidos.service';
import { ReservasService } from '../../core/services/reservas.service';
import { HeaderComponent } from '../../shared/header/header';

interface ItemCarritoVista {
  detalle: DetalleCarrito;
  variante?: Variante;
  producto?: Producto;
  subtotal: number;
}

@Component({
  selector: 'app-carrito',
  imports: [CommonModule, FormsModule, RouterLink, HeaderComponent],
  templateUrl: './carrito.html',
  styleUrl: './carrito.css'
})
export class CarritoPage implements OnInit {
  private carritoService = inject(CarritoService);
  private productosService = inject(ProductosService);
  private variantesService = inject(VariantesService);
  private sucursalesService = inject(SucursalesService);
  private pedidosService = inject(PedidosService);
  private reservasService = inject(ReservasService);
  private router = inject(Router);
  private cdr = inject(ChangeDetectorRef);

  items: ItemCarritoVista[] = [];
  sucursales: Sucursal[] = [];

  cargando = true;
  error = '';
  mensaje = '';
  actualizandoId: number | null = null;

  // Checkout
  mostrarCheckout: 'ninguno' | 'compra' | 'reserva' = 'ninguno';
  sucursalSeleccionada: number | null = null;
  fechaReserva = '';
  observacionesReserva = '';
  procesandoCheckout = false;

  ngOnInit(): void {
    this.cargarCarrito();
    this.sucursalesService.listar(true).subscribe({
      next: (sucursales) => {
        this.sucursales = sucursales;
        this.cdr.detectChanges();
      }
    });
  }

  cargarCarrito(): void {
    this.cargando = true;
    this.error = '';
    this.mensaje = '';

    this.carritoService.obtener().subscribe({
      next: (carrito) => this.enriquecerItems(carrito),
      error: (error) => {
        this.cargando = false;
        if (error.status === 401) {
          this.error = 'Inicia sesión para ver tu carrito.';
        } else {
          this.error = 'No se pudo cargar el carrito.';
        }
        this.cdr.detectChanges();
      }
    });
  }

  private enriquecerItems(carrito: Carrito): void {
    if (carrito.detalles.length === 0) {
      this.items = [];
      this.cargando = false;
      this.cdr.detectChanges();
      return;
    }

    const solicitudes = carrito.detalles.map((detalle) =>
      this.variantesService.obtenerPorId(detalle.variante_id).pipe(
        catchError(() => of(null))
      )
    );

    forkJoin(solicitudes).subscribe((variantes) => {
      const productoIds = [
        ...new Set(
          variantes.filter((v): v is Variante => !!v).map(v => v.producto_id)
        )
      ];

      if (productoIds.length === 0) {
        this.items = carrito.detalles.map(detalle => ({ detalle, subtotal: 0 }));
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

        this.items = carrito.detalles.map((detalle, i) => {
          const variante = variantes[i] ?? undefined;
          const producto = variante ? mapaProductos.get(variante.producto_id) : undefined;
          const subtotal = producto ? producto.precio * detalle.cantidad : 0;

          return { detalle, variante, producto, subtotal };
        });

        this.cargando = false;
        this.cdr.detectChanges();
      });
    });
  }

  get total(): number {
    return this.items.reduce((acc, item) => acc + item.subtotal, 0);
  }

  cambiarCantidad(item: ItemCarritoVista, nuevaCantidad: number): void {
    if (nuevaCantidad < 1) return;

    this.actualizandoId = item.detalle.id;
    this.error = '';

    this.carritoService.actualizarItem(item.detalle.id, nuevaCantidad).subscribe({
      next: () => {
        this.actualizandoId = null;
        this.cargarCarrito();
      },
      error: (error) => {
        this.actualizandoId = null;
        this.error = error.error?.detail || 'No se pudo actualizar la cantidad.';
        this.cdr.detectChanges();
      }
    });
  }

  eliminarItem(item: ItemCarritoVista): void {
    this.carritoService.eliminarItem(item.detalle.id).subscribe({
      next: () => {
        this.mensaje = 'Prenda eliminada del carrito.';
        this.cargarCarrito();
      },
      error: () => {
        this.error = 'No se pudo eliminar la prenda.';
        this.cdr.detectChanges();
      }
    });
  }

  vaciarCarrito(): void {
    if (!confirm('¿Vaciar todo el carrito?')) return;

    this.carritoService.vaciar().subscribe({
      next: () => {
        this.mensaje = 'Carrito vaciado.';
        this.cargarCarrito();
      },
      error: () => {
        this.error = 'No se pudo vaciar el carrito.';
        this.cdr.detectChanges();
      }
    });
  }

  // ----- Checkout -----
  abrirCheckout(tipo: 'compra' | 'reserva'): void {
    this.mostrarCheckout = tipo;
    this.sucursalSeleccionada = this.sucursales[0]?.id ?? null;
    this.error = '';
    this.mensaje = '';
  }

  cerrarCheckout(): void {
    this.mostrarCheckout = 'ninguno';
  }

  onImagenError(event: Event, item: ItemCarritoVista): void {
    const img = event.target as HTMLImageElement;
    img.style.display = 'none';
    if (item.producto) {
      item.producto.imagen_url = null;
    }
    this.cdr.detectChanges();
  }

  confirmarCompra(): void {
    if (!this.sucursalSeleccionada) {
      this.error = 'Selecciona una sucursal.';
      return;
    }

    this.procesandoCheckout = true;
    this.error = '';

    this.pedidosService.crearDesdeCarrito(this.sucursalSeleccionada).subscribe({
      next: (pedido) => {
        this.procesandoCheckout = false;
        this.mostrarCheckout = 'ninguno';
        this.router.navigate(['/checkout', pedido.id]);
      },
      error: (error) => {
        this.procesandoCheckout = false;
        this.error = error.error?.detail || 'No se pudo completar la compra.';
        this.cdr.detectChanges();
      }
    });
  }

  confirmarReserva(): void {
    if (!this.sucursalSeleccionada) {
      this.error = 'Selecciona una sucursal.';
      return;
    }

    if (!this.fechaReserva) {
      this.error = 'Selecciona una fecha y hora para probarte las prendas.';
      return;
    }

    const detalles = this.items
      .filter(item => item.variante)
      .map(item => ({
        variante_id: item.variante!.id,
        cantidad: item.detalle.cantidad
      }));

    if (detalles.length === 0) {
      this.error = 'No hay prendas válidas para reservar.';
      return;
    }

    this.procesandoCheckout = true;
    this.error = '';

    this.reservasService.crear({
      sucursal_id: this.sucursalSeleccionada,
      fecha_reserva: new Date(this.fechaReserva).toISOString(),
      observaciones: this.observacionesReserva.trim() || null,
      detalles
    }).subscribe({
      next: () => {
        this.procesandoCheckout = false;
        this.mostrarCheckout = 'ninguno';
        this.router.navigate(['/reservas']);
      },
      error: (error) => {
        this.procesandoCheckout = false;
        this.error = error.error?.detail || 'No se pudo crear la reserva.';
        this.cdr.detectChanges();
      }
    });
  }
}
