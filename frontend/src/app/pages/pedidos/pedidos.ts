import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { PedidosService, Pedido } from '../../core/services/pedidos.service';
import { PagosService } from '../../core/services/pagos.service';
import { TiposPagoService, TipoPago } from '../../core/services/tipos-pago.service';
import { ReciboComponent } from '../../shared/recibo/recibo';
import { HeaderComponent } from '../../shared/header/header';
import { FechaBoliviaPipe } from '../../core/pipes/fecha-bolivia.pipe';

@Component({
  selector: 'app-pedidos',
  imports: [CommonModule, FormsModule, RouterLink, HeaderComponent, ReciboComponent, FechaBoliviaPipe],
  templateUrl: './pedidos.html',
  styleUrl: './pedidos.css'
})
export class PedidosPage implements OnInit {
  private pedidosService = inject(PedidosService);
  private pagosService = inject(PagosService);
  private tiposPagoService = inject(TiposPagoService);
  private cdr = inject(ChangeDetectorRef);

  pedidos: Pedido[] = [];
  tiposPago: TipoPago[] = [];
  cargando = true;
  error = '';
  mensaje = '';

  pedidoPagando: number | null = null;
  metodoPago = 'tarjeta';
  referenciaPago = '';
  procesandoPago = false;

  pedidoParaComprobante: Pedido | null = null;

  etiquetasEstado: Record<string, string> = {
    pendiente: 'Pendiente',
    pagado: 'Pagado',
    procesando: 'Procesando',
    enviado: 'Enviado',
    entregado: 'Entregado',
    cancelado: 'Cancelado'
  };

  ngOnInit(): void {
    const navegacion = history.state;
    if (navegacion?.pedidoCreado) {
      this.mensaje = `Pedido #${navegacion.pedidoCreado} creado correctamente. Puedes pagarlo ahora.`;
    }
    this.tiposPagoService.listar(true).subscribe({
      next: (tipos) => {
        this.tiposPago = tipos;
        if (tipos.length > 0) this.metodoPago = tipos[0].nombre;
        this.cdr.detectChanges();
      }
    });
    this.cargarPedidos();
  }

  cargarPedidos(): void {
    this.cargando = true;
    this.error = '';

    this.pedidosService.listarMisPedidos().subscribe({
      next: (pedidos) => {
        this.pedidos = pedidos;
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.cargando = false;
        this.error = error.status === 401
          ? 'Inicia sesión para ver tus pedidos.'
          : 'No se pudieron cargar tus pedidos.';
        this.cdr.detectChanges();
      }
    });
  }

  cancelarPedido(pedido: Pedido): void {
    if (!confirm(`¿Cancelar el pedido #${pedido.id}?`)) return;

    this.pedidosService.cancelar(pedido.id).subscribe({
      next: () => {
        this.mensaje = `Pedido #${pedido.id} cancelado.`;
        this.cargarPedidos();
      },
      error: (error) => {
        this.error = error.error?.detail || 'No se pudo cancelar el pedido.';
        this.cdr.detectChanges();
      }
    });
  }

  puedeCancelar(pedido: Pedido): boolean {
    return !['cancelado', 'entregado'].includes(pedido.estado);
  }

  claseEstado(estado: string): string {
    const clases: Record<string, string> = {
      pendiente: 'bg-amber-50 text-amber-700',
      pagado: 'bg-blue-50 text-blue-700',
      procesando: 'bg-blue-50 text-blue-700',
      enviado: 'bg-indigo-50 text-indigo-700',
      entregado: 'bg-emerald-50 text-emerald-700',
      cancelado: 'bg-red-50 text-red-700'
    };
    return clases[estado] || 'bg-neutral-100 text-neutral-700';
  }

  abrirPago(pedido: Pedido): void {
    this.pedidoPagando = pedido.id;
    this.metodoPago = 'tarjeta';
    this.referenciaPago = '';
    this.error = '';
  }

  cerrarPago(): void {
    this.pedidoPagando = null;
  }

  confirmarPago(pedido: Pedido): void {
    this.procesandoPago = true;
    this.error = '';

    this.pagosService.registrarPago({
      pedido_id: pedido.id,
      metodo: this.metodoPago,
      monto: pedido.total,
      referencia: this.referenciaPago.trim() || null
    }).subscribe({
      next: () => {
        this.procesandoPago = false;
        this.pedidoPagando = null;
        this.mensaje = `Pago del pedido #${pedido.id} procesado correctamente.`;
        this.cargarPedidos();
      },
      error: (error) => {
        this.procesandoPago = false;
        this.error = error.error?.detail || 'No se pudo procesar el pago.';
        this.cdr.detectChanges();
      }
    });
  }

  verComprobante(pedido: Pedido): void {
    this.pedidoParaComprobante = pedido;
  }

  cerrarComprobante(): void {
    this.pedidoParaComprobante = null;
  }
}
