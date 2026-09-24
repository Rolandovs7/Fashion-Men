import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink, Router } from '@angular/router';
import { PedidosService, Pedido } from '../../core/services/pedidos.service';
import { PagosService } from '../../core/services/pagos.service';
import { TiposPagoService, TipoPago } from '../../core/services/tipos-pago.service';
import { ReciboComponent } from '../../shared/recibo/recibo';
import { HeaderComponent } from '../../shared/header/header';
import { FechaBoliviaPipe } from '../../core/pipes/fecha-bolivia.pipe';
import {
  ButtonComponent,
  InputComponent,
  SelectComponent,
  ModalComponent,
  AlertComponent,
  BadgeComponent,
  BadgeTipo,
  LoaderComponent,
  EmptyStateComponent,
  PriceComponent,
  FooterComponent
} from '../../shared/ui';

@Component({
  selector: 'app-pedidos',
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    HeaderComponent,
    ReciboComponent,
    FechaBoliviaPipe,
    ButtonComponent,
    InputComponent,
    SelectComponent,
    ModalComponent,
    AlertComponent,
    BadgeComponent,
    LoaderComponent,
    EmptyStateComponent,
    PriceComponent,
    FooterComponent
  ],
  templateUrl: './pedidos.html',
  styleUrl: './pedidos.css'
})
export class PedidosPage implements OnInit {
  private pedidosService = inject(PedidosService);
  private pagosService = inject(PagosService);
  private tiposPagoService = inject(TiposPagoService);
  private cdr = inject(ChangeDetectorRef);
  private router = inject(Router);

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
  pedidoACancelar: Pedido | null = null;

  etiquetasEstado: Record<string, string> = {
    pendiente: 'Pendiente',
    pagado: 'Pagado',
    procesando: 'Procesando',
    enviado: 'Enviado',
    entregado: 'Entregado',
    cancelado: 'Cancelado'
  };

  get opcionesMetodoPago(): { valor: string; etiqueta: string }[] {
    return this.tiposPago.map((t) => ({ valor: t.nombre, etiqueta: t.nombre }));
  }

  irAlCatalogo(): void {
    this.router.navigate(['/catalogo']);
  }

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
    this.error = '';
    this.pedidoACancelar = pedido;
  }

  cerrarConfirmacionCancelacion(): void {
    this.pedidoACancelar = null;
  }

  confirmarCancelacion(): void {
    if (!this.pedidoACancelar) return;

    const pedido = this.pedidoACancelar;
    this.pedidoACancelar = null;

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

  tipoBadge(estado: string): BadgeTipo {
    const mapa: Record<string, BadgeTipo> = {
      pendiente: 'aviso',
      pagado: 'info',
      procesando: 'info',
      enviado: 'acento',
      entregado: 'exito',
      cancelado: 'error'
    };
    return mapa[estado] || 'neutral';
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
