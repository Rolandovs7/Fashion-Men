/**
 * [Segundo Parcial] CU25 - Dashboard analítico
 * [Segundo Parcial] RNF02 - Aislamiento por empresa
 */
import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { BaseChartDirective } from 'ng2-charts';
import { ChartConfiguration, ChartData, ChartType } from 'chart.js';
import { AdminShellComponent } from '../../shared/admin-shell/admin-shell';
import { LoaderComponent, AlertComponent } from '../../shared/ui';

@Component({
  selector: 'app-admin-dashboard',
  imports: [CommonModule, AdminShellComponent, BaseChartDirective, LoaderComponent, AlertComponent],
  templateUrl: './admin-dashboard.html'
})
export class AdminDashboard implements OnInit {
  private http = inject(HttpClient);
  private cdr = inject(ChangeDetectorRef);
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/reportes';

  cargando = false;
  error = '';

  kpis: any = {};
  ventasMes: any[] = [];
  ventasSucursal: any[] = [];

  barChartType: ChartType = 'bar';
  barChartData: any = {
    labels: [],
    datasets: [{ data: [], label: 'Ventas por mes (Bs)' }]
  };
  barChartOptions: any = {
    responsive: true
  };

  pieChartType: ChartType = 'pie';
  pieChartData: ChartData<'pie'> = {
    labels: [],
    datasets: [{ data: [] }]
  };
  pieChartOptions: any = {
    responsive: true
  };

  ngOnInit(): void {
    this.cargar();
  }

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  cargar(): void {
    this.cargando = true;
    this.error = '';
    this.http.get<any>(`${this.apiUrl}/dashboard`, { headers: this.headers() }).subscribe({
      next: (res) => {
        this.kpis = res;
        this.cdr.detectChanges();
      }
    });
    this.http.get<any[]>(`${this.apiUrl}/ventas-por-mes?meses=12`, { headers: this.headers() }).subscribe({
      next: (res) => {
        this.ventasMes = res;
        this.barChartData = {
          labels: res.map((r) => r.mes),
          datasets: [{ data: res.map((r) => r.total), label: 'Ventas por mes (Bs)' }]
        };
        this.cdr.detectChanges();
      }
    });
    this.http.get<any[]>(`${this.apiUrl}/ventas-por-sucursal`, { headers: this.headers() }).subscribe({
      next: (res) => {
        this.ventasSucursal = res;
        this.pieChartData = {
          labels: res.map((r) => r.sucursal),
          datasets: [{ data: res.map((r) => r.total_ventas) }]
        };
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.cargando = false;
        this.cdr.detectChanges();
      }
    });
  }
}
