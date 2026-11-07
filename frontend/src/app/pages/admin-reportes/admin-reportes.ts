/**
 * [Segundo Parcial] CU22 - Exportación de reportes
 * [Segundo Parcial] CU25 - Dashboard analítico
 * [Segundo Parcial] RNF02 - Aislamiento por empresa
 */
import {
  Component, OnInit, AfterViewInit, OnDestroy,
  inject, ChangeDetectorRef, ViewChild, ElementRef,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Chart, registerables } from 'chart.js';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

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
import {
  ButtonComponent,
  AlertComponent,
  BadgeComponent,
  SkeletonComponent,
} from '../../shared/ui';

Chart.register(...registerables);

@Component({
  selector: 'app-admin-reportes',
  imports: [CommonModule, FormsModule, AdminShellComponent, ButtonComponent, AlertComponent, BadgeComponent, SkeletonComponent],
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

  // Paleta "Quiet Editorial Luxury" (tokens ms-*):
  // #0a0a0a ms-black · #d97706 ms-amber · #fe932c ms-amber-soft
  // #525252 ms-slate · #e7e5e4 ms-stone-200.
  private readonly PALETA = [
    '#0a0a0a', '#d97706', '#fe932c', '#525252', '#e7e5e4',
    '#0a0a0a', '#d97706', '#fe932c', '#525252', '#e7e5e4',
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

  exportarExcel(): void {
    try {
      const datos = this.productosTop.map((p: any) => ({
        'Fecha de Venta': p.fecha || '',
        Sucursal: p.sucursal || '',
        Cliente: p.cliente || '',
        'Método de Pago': p.metodo_pago || '',
        Producto: p.nombre || p.producto || '',
        'Cantidad Vendida': p.cantidad || p.total_vendido || 0,
        'Ingresos (Bs)': Number(p.ingresos || 0).toFixed(2),
      }));
      let totalIngresos = 0;
      let totalPrendas = 0;
      for (const p of this.productosTop as any[]) {
        totalIngresos += Number(p.ingresos || 0);
        totalPrendas += Number(p.cantidad || p.total_vendido || 0);
      }
      datos.push({
        'Fecha de Venta': '',
        Sucursal: '',
        Cliente: '',
        'Método de Pago': '',
        Producto: 'TOTAL GENERAL',
        'Cantidad Vendidas': totalPrendas,
        'Ingresos (Bs)': totalIngresos.toFixed(2),
      } as any);
      const ws = XLSX.utils.json_to_sheet(datos);
      const colWidths = [
        { wch: 18 },
        { wch: 18 },
        { wch: 28 },
        { wch: 16 },
        { wch: 40 },
        { wch: 18 },
        { wch: 18 },
      ];
      ws['!cols'] = colWidths;
      const wb = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(wb, ws, 'Reporte Ventas');
      XLSX.writeFile(wb, 'reporte_menstyle_ventas.xlsx');
    } catch (e) {
      // ignore
    }
  }

  exportarPDF(): void {
    try {
      const doc = new jsPDF({ orientation: 'landscape' });
      const fecha = new Date().toLocaleString();
      doc.setFontSize(16);
      doc.text('MenStyle - Reporte de Ventas', 14, 16);
      doc.setFontSize(9);
      doc.text(`Fecha de emisión: ${fecha}`, 14, 22);
      doc.text('Empresa: MenStyle', 14, 27);

      const rows = this.productosTop.map((p: any) => [
        p.fecha || '',
        p.sucursal || '',
        p.cliente || '',
        p.metodo_pago || '',
        p.nombre || p.producto || '',
        String(p.cantidad || p.total_vendido || 0),
        Number(p.ingresos || 0).toFixed(2),
      ]);
      let totalIngresos = 0;
      let totalPrendas = 0;
      for (const p of this.productosTop as any[]) {
        totalIngresos += Number(p.ingresos || 0);
        totalPrendas += Number(p.cantidad || p.total_vendido || 0);
      }
      rows.push(['', '', '', '', 'TOTAL GENERAL', String(totalPrendas), totalIngresos.toFixed(2)]);

      autoTable(doc, {
        head: [['Fecha', 'Sucursal', 'Cliente', 'Método Pago', 'Producto', 'Cantidad', 'Ingresos (Bs)']],
        body: rows,
        startY: 32,
        styles: { fontSize: 7, cellPadding: 2 },
        headStyles: { fillColor: [10, 10, 10], textColor: 255 },
        alternateRowStyles: { fillColor: [245, 245, 245] },
        didParseCell: (data: any) => {
          if (data.row.index === rows.length - 1 && data.section === 'body') {
            data.cell.styles.fillColor = [217, 119, 6];
            data.cell.styles.textColor = [255, 255, 255];
            data.cell.styles.fontStyle = 'bold';
          }
        }
      });
      doc.save('reporte_menstyle_ventas.pdf');
    } catch (e) {
      // ignore
    }
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
          pointBackgroundColor: '#d97706',
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
        scales: {
          y: {
            beginAtZero: true,
            grid: { color: '#e7e5e4' },
            ticks: { color: '#525252', callback: (v) => `Bs ${v}` },
          },
          x: { grid: { color: '#e7e5e4' }, ticks: { color: '#525252' } },
        },
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
          legend: {
            position: 'bottom',
            labels: { boxWidth: 12, padding: 12, color: '#525252' },
          },
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
        scales: {
          x: { beginAtZero: true, ticks: { precision: 0, color: '#525252' }, grid: { color: '#e7e5e4' } },
          y: { grid: { display: false }, ticks: { color: '#525252' } },
        },
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
          backgroundColor: '#d97706',
          borderRadius: 6,
        }],
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: { callbacks: { label: (ctx) => ` Bs ${(ctx.parsed.y ?? 0).toFixed(2)}` } },
        },
        scales: {
          y: {
            beginAtZero: true,
            grid: { color: '#e7e5e4' },
            ticks: { color: '#525252', callback: (v) => `Bs ${v}` },
          },
          x: { grid: { color: '#e7e5e4' }, ticks: { color: '#525252' } },
        },
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