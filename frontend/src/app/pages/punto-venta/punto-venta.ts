import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { UsuariosService, Usuario } from '../../core/services/usuarios.service';
import { SucursalesService, Sucursal } from '../../core/services/sucursales.service';
import { ProductosService, Producto } from '../../core/services/productos.service';
import { VariantesService, Variante } from '../../core/services/variantes.service';
import { PedidosService, ItemVentaPresencial, Pedido } from '../../core/services/pedidos.service';
import { TiposPagoService, TipoPago } from '../../core/services/tipos-pago.service';
import { AdminShellComponent } from '../../shared/admin-shell/admin-shell';
import { ReciboComponent } from '../../shared/recibo/recibo';

interface ItemCarritoPOS {
  producto: Producto;
  variante: Variante;
  cantidad: number;
}

@Component({
  selector: 'app-punto-venta',
  imports: [CommonModule, FormsModule, AdminShellComponent, ReciboComponent],
  templateUrl: './punto-venta.html',
  styleUrl: './punto-venta.css'
})
export class PuntoVenta implements OnInit {
  private usuariosService = inject(UsuariosService);
  private sucursalesService = inject(SucursalesService);
  private productosService = inject(ProductosService);
  private variantesService = inject(VariantesService);
  private pedidosService = inject(PedidosService);
  private tiposPagoService = inject(TiposPagoService);
  private router = inject(Router);
  private cdr = inject(ChangeDetectorRef);

  clientes: Usuario[] = [];
  sucursales: Sucursal[] = [];
  productos: Producto[] = [];
  variantesDisponibles: Variante[] = [];
  tiposPago: TipoPago[] = [];

  clienteId: number | null = null;
  sucursalId: number | null = null;
  metodoPago = 'efectivo';

  productoSeleccionadoId: number | null = null;
  varianteSeleccionadaId: number | null = null;
  cantidadSeleccionada = 1;

  itemsVenta: ItemCarritoPOS[] = [];

  cargando = true;
  procesando = false;
  error = '';
  mensaje = '';

  pedidoParaComprobante: Pedido | null = null;

  ngOnInit(): void {
    this.tiposPagoService.listar(true).subscribe({
      next: (tipos) => {
        this.tiposPago = tipos;
        if (tipos.length > 0) this.metodoPago = tipos[0].nombre;
        this.cdr.detectChanges();
      }
    });

    this.usuariosService.listar().subscribe({
      next: (usuarios) => {
        this.clientes = usuarios.filter(u => u.rol === 'cliente' && u.activo);
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: () => { this.cargando = false; }
    });

    this.sucursalesService.listar(true).subscribe({
      next: (s) => { this.sucursales = s; this.cdr.detectChanges(); }
    });

    this.productosService.listar().subscribe({
      next: (p) => { this.productos = p.filter(prod => prod.activo); this.cdr.detectChanges(); }
    });
  }

  cargarVariantes(): void {
    this.varianteSeleccionadaId = null;
    if (!this.productoSeleccionadoId) {
      this.variantesDisponibles = [];
      return;
    }

    this.variantesService.listarPorProducto(this.productoSeleccionadoId).subscribe({
      next: (variantes) => {
        this.variantesDisponibles = variantes.filter(v => v.stock_disponible > 0);
        this.cdr.detectChanges();
      }
    });
  }

  agregarItem(): void {
    const producto = this.productos.find(p => p.id === this.productoSeleccionadoId);
    const variante = this.variantesDisponibles.find(v => v.id === this.varianteSeleccionadaId);

    if (!producto || !variante) {
      this.error = 'Selecciona un producto y una variante válidos.';
      return;
    }

    if (this.cantidadSeleccionada < 1 || this.cantidadSeleccionada > variante.stock_disponible) {
      this.error = `Cantidad inválida. Disponible: ${variante.stock_disponible}.`;
      return;
    }

    const existente = this.itemsVenta.find(i => i.variante.id === variante.id);
    if (existente) {
      existente.cantidad += this.cantidadSeleccionada;
    } else {
      this.itemsVenta.push({ producto, variante, cantidad: this.cantidadSeleccionada });
    }

    this.error = '';
    this.cantidadSeleccionada = 1;
  }

  quitarItem(item: ItemCarritoPOS): void {
    this.itemsVenta = this.itemsVenta.filter(i => i !== item);
  }

  get total(): number {
    return this.itemsVenta.reduce((acc, i) => acc + i.producto.precio * i.cantidad, 0);
  }

  registrarVenta(): void {
    if (!this.clienteId) {
      this.error = 'Selecciona el cliente que realiza la compra.';
      return;
    }
    if (!this.sucursalId) {
      this.error = 'Selecciona la sucursal donde se realiza la venta.';
      return;
    }
    if (this.itemsVenta.length === 0) {
      this.error = 'Agrega al menos una prenda a la venta.';
      return;
    }

    const items: ItemVentaPresencial[] = this.itemsVenta.map(i => ({
      variante_id: i.variante.id,
      cantidad: i.cantidad
    }));

    this.procesando = true;
    this.error = '';

    this.pedidosService.crearVentaPresencial(
      this.clienteId, this.sucursalId, this.metodoPago, items
    ).subscribe({
      next: (pedido) => {
        this.procesando = false;
        this.mensaje = `Venta #${pedido.id} registrada y pagada correctamente por Bs ${pedido.total.toFixed(2)}.`;
        this.itemsVenta = [];
        this.clienteId = null;
        this.pedidoParaComprobante = pedido;
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.procesando = false;
        this.error = error.error?.detail || 'No se pudo registrar la venta.';
        this.cdr.detectChanges();
      }
    });
  }

  get nombreSucursalSeleccionada(): string | null {
    const sucursal = this.sucursales.find(s => s.id === this.sucursalId);
    return sucursal ? `${sucursal.nombre} — ${sucursal.ciudad}` : null;
  }

  cerrarComprobante(): void {
    this.pedidoParaComprobante = null;
  }
}
