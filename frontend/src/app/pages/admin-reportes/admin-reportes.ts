import {
  Component, OnInit, AfterViewInit, OnDestroy,
  inject, ChangeDetectorRef, ViewChild, ElementRef,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Chart, registerables } from 'chart.js';

import {
  ReportsService,
  DashboardKpis,
  ProductoTop,
  VentaMes,
  VentaMetodoPago,
  InventarioBajo,
  VentaSucursal,
} from '../../core/services/reports.service';
import { AdminShellComponent } from '../../shared/admin-shell/admin-shell';

Chart.register(...registerables);

@Component({
  selector: 'app-admin-reportes',
  imports: [CommonModule, FormsModule, AdminShellComponent],
  templateUrl: './admin-reportes.html',
  styleUrl: './admin-reportes.css',
})
export class AdminReportes implements OnInit, AfterViewInit, OnDestroy {
  private reportsService = inject(ReportsService);
  private cdr = inject(ChangeDetectorRef);

  @ViewChild('canvasVentasMes') canvasVentasMes!: ElementRef<HTMLCanvasElement>;
  @ViewChild('canvasMetodoPago') canvasMetodoPago!: ElementRef<HTMLCanvasElement>;
  @ViewChild('canvasProductosTop') canvasProductosTop!: ElementRef<HTMLCanvasElement>;
  @ViewChild('canvasVentasSucursal') canvasVentasSucursal!: ElementRef<HTMLCanvasElement>;

  cargando = true;
  error = '';
  viewReady = false;

  meses = 12;
  umbralStock = 5;

  kpis: DashboardKpis | null = null;
  ventasMes: VentaMes[] = [];
  metodosPago: VentaMetodoPago[] = [];
  productosTop: ProductoTop[] = [];
  inventarioBajo: InventarioBajo[] = [];
  ventasSucursal: VentaSucursal[] = [];

  private chartVentasMes?: Chart;
  private chartMetodoPago?: Chart;
  private chartProductosTop?: Chart;
  private chartVentasSucursal?: Chart;

  private readonly PALETA = [
    '#0a0a0a', '#10b981', '#3b82f6', '#f59e0b', '#ef4444',
    '#8b5cf6', '#ec4899', '#14b8a6', '#f97316', '#6366f1',
  ];

  ngOnInit(): void {
    this.cargarTodo();
  }

  ngAfterViewInit(): void {
    this.viewReady = true;
    if (!this.cargando) this.renderizarGraficos();
  }

  ngOnDestroy(): void {
    this.chartVentasMes?.destroy();
    this.chartMetodoPago?.destroy();
    this.chartProductosTop?.destroy();
    this.chartVentasSucursal?.destroy();
  }

  cargarTodo(): void {
    this.cargando = true;
    this.error = '';

    let pendientes = 6;
    const listo = () => {
      pendientes--;
      if (pendientes === 0) {
        this.cargando = false;
        this.cdr.detectChanges();
        this.renderizarGraficos();
      }
    };

    const fallo = (err: any) => {
      this.error = err?.error?.detail || 'Error al cargar reportes.';
      this.cargando = false;
      this.cdr.detectChanges();
    };

    this.reportsService.dashboard().subscribe({
      next: (d) => { this.kpis = d; listo(); }, error: fallo,
    });
    this.reportsService.ventasPorMes(this.meses).subscribe({
      next: (d) => { this.ventasMes = d; listo(); }, error: fallo,
    });
    this.reportsService.ventasPorMetodoPago().subscribe({
      next: (d) => {
        this.metodosPago = d;
        this.cdr.detectChanges();
        this.renderMetodoPago();
        listo();
      },
      error: fallo,
    });
    this.reportsService.productosTop(10).subscribe({
      next: (d) => { this.productosTop = d; listo(); }, error: fallo,
    });
    this.reportsService.inventarioBajo(this.umbralStock, 20).subscribe({
      next: (d) => { this.inventarioBajo = d; listo(); }, error: fallo,
    });
    this.reportsService.ventasPorSucursal().subscribe({
      next: (d) => { this.ventasSucursal = d; listo(); }, error: fallo,
    });
  }

  private renderizarGraficos(): void {
    if (!this.viewReady) return;
    this.renderVentasMes();
    this.renderMetodoPago();
    this.renderProductosTop();
    this.renderVentasSucursal();
  }

  private renderVentasMes(): void {
    this.chartVentasMes?.destroy();
    if (!this.canvasVentasMes) return;
    this.chartVentasMes = new Chart(this.canvasVentasMes.nativeElement, {
      type: 'line',
      data: {
        labels: this.ventasMes.map((v) => v.mes),
        datasets: [{
          label: 'Ventas (Bs)',
          data: this.ventasMes.map((v) => v.total),
          borderColor: '#0a0a0a',
          backgroundColor: 'rgba(10,10,10,0.08)',
          borderWidth: 2.5,
          tension: 0.35,
          fill: true,
          pointBackgroundColor: '#10b981',
          pointRadius: 4,
          pointHoverRadius: 6,
        }],
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: { callbacks: { label: (ctx) => ` Bs ${(ctx.parsed.y ?? 0).toFixed(2)}` } },
        },
        scales: { y: { beginAtZero: true, ticks: { callback: (v) => `Bs ${v}` } } },
      },
    });
  }

  private renderMetodoPago(): void {
    this.chartMetodoPago?.destroy();
    if (!this.canvasMetodoPago || this.metodosPago.length === 0) return;
    this.chartMetodoPago = new Chart(this.canvasMetodoPago.nativeElement, {
      type: 'doughnut',
      data: {
        labels: this.metodosPago.map((m) => m.metodo),
        datasets: [{
          data: this.metodosPago.map((m) => m.total),
          backgroundColor: this.PALETA.slice(0, this.metodosPago.length),
          borderWidth: 2,
          borderColor: '#ffffff',
        }],
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: {
          legend: { position: 'bottom', labels: { boxWidth: 12, padding: 12 } },
          tooltip: { callbacks: { label: (ctx) => ` ${ctx.label}: Bs ${(ctx.parsed as number).toFixed(2)}` } },
        },
        cutout: '60%',
      },
    });
  }

  private renderProductosTop(): void {
    this.chartProductosTop?.destroy();
    if (!this.canvasProductosTop) return;
    this.chartProductosTop = new Chart(this.canvasProductosTop.nativeElement, {
      type: 'bar',
      data: {
        labels: this.productosTop.map((p) => p.nombre),
        datasets: [{
          label: 'Unidades vendidas',
          data: this.productosTop.map((p) => p.total_vendido),
          backgroundColor: '#0a0a0a',
          borderRadius: 6,
        }],
      },
      options: {
        indexAxis: 'y', responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: { x: { beginAtZero: true, ticks: { precision: 0 } } },
      },
    });
  }

  private renderVentasSucursal(): void {
    this.chartVentasSucursal?.destroy();
    if (!this.canvasVentasSucursal) return;
    this.chartVentasSucursal = new Chart(this.canvasVentasSucursal.nativeElement, {
      type: 'bar',
      data: {
        labels: this.ventasSucursal.map((s) => `${s.sucursal} (${s.ciudad})`),
        datasets: [{
          label: 'Ventas (Bs)',
          data: this.ventasSucursal.map((s) => s.total_ventas),
          backgroundColor: '#10b981',
          borderRadius: 6,
        }],
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: { callbacks: { label: (ctx) => ` Bs ${(ctx.parsed.y ?? 0).toFixed(2)}` } },
        },
        scales: { y: { beginAtZero: true, ticks: { callback: (v) => `Bs ${v}` } } },
      },
    });
  }

  aplicarFiltros(): void {
    this.reportsService.ventasPorMes(this.meses).subscribe((d) => {
      this.ventasMes = d;
      this.renderVentasMes();
    });
    this.reportsService.inventarioBajo(this.umbralStock, 20).subscribe((d) => {
      this.inventarioBajo = d;
    });
  }

  formatearBs(valor: number): string {
    return `Bs ${(valor ?? 0).toLocaleString('es-BO', {
      minimumFractionDigits: 2, maximumFractionDigits: 2,
    })}`;
  }
}