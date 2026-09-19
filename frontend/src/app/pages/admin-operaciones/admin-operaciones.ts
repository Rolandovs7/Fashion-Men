import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { PedidosService, Pedido } from '../../core/services/pedidos.service';
import { ReservasService, Reserva } from '../../core/services/reservas.service';
import { SucursalesService, Sucursal } from '../../core/services/sucursales.service';
import { AdminShellComponent } from '../../shared/admin-shell/admin-shell';
import { ReciboComponent } from '../../shared/recibo/recibo';
import { FechaBoliviaPipe } from '../../core/pipes/fecha-bolivia.pipe';

type Pestana = 'pedidos' | 'reservas';

@Component({
  selector: 'app-admin-operaciones',
  imports: [CommonModule, FormsModule, AdminShellComponent, ReciboComponent, FechaBoliviaPipe],
  templateUrl: './admin-operaciones.html',
  styleUrl: './admin-operaciones.css'
})
export class AdminOperaciones implements OnInit {
  private pedidosService = inject(PedidosService);
  private reservasService = inject(ReservasService);
  private sucursalesService = inject(SucursalesService);
  pedidoParaComprobante: Pedido | null = null;
  private cdr = inject(ChangeDetectorRef);

  pestana: Pestana = 'pedidos';

  pedidos: Pedido[] = [];
  reservas: Reserva[] = [];
  sucursales: Sucursal[] = [];

  cargando = false;
  error = '';
  mensaje = '';

  estadosPedido = ['pendiente', 'pagado', 'procesando', 'enviado', 'entregado', 'cancelado'];
  estadosReserva = ['pendiente', 'confirmada', 'completada', 'cancelada'];

  ngOnInit(): void {
    this.sucursalesService.listar(false).subscribe({ next: (s) => (this.sucursales = s) });
    this.cargarPedidos();
    this.cargarReservas();
  }

  cambiarPestana(pestana: Pestana): void {
    this.pestana = pestana;
    this.error = '';
    this.mensaje = '';
  }

  cargarPedidos(): void {
    this.cargando = true;
    this.pedidosService.listarTodos().subscribe({
      next: (pedidos) => {
        this.pedidos = pedidos;
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.cargando = false;
      }
    });
  }

  cargarReservas(): void {
    this.reservasService.listarTodas().subscribe({
      next: (reservas) => {
        this.reservas = reservas;
        this.cdr.detectChanges();
      }
    });
  }

  nombreSucursal(id: number): string {
    return this.sucursales.find(s => s.id === id)?.nombre ?? `Sucursal #${id}`;
  }

  cambiarEstadoPedido(pedido: Pedido, nuevoEstado: string): void {
    if (nuevoEstado === pedido.estado) return;

    this.pedidosService.cambiarEstado(pedido.id, nuevoEstado).subscribe({
      next: () => {
        this.mensaje = `Pedido #${pedido.id} actualizado a "${nuevoEstado}".`;
        this.cargarPedidos();
      },
      error: (error) => {
        this.error = error.error?.detail || 'No se pudo actualizar el pedido.';
        this.cdr.detectChanges();
      }
    });
  }

  cambiarEstadoReserva(reserva: Reserva, nuevoEstado: string): void {
    if (nuevoEstado === reserva.estado) return;

    this.reservasService.cambiarEstado(reserva.id, nuevoEstado).subscribe({
      next: () => {
        this.mensaje = `Reserva #${reserva.id} actualizada a "${nuevoEstado}".`;
        this.cargarReservas();
      },
      error: (error) => {
        this.error = error.error?.detail || 'No se pudo actualizar la reserva.';
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
