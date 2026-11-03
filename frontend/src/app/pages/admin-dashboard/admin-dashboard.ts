/**
 * [Segundo Parcial] CU25 - Dashboard analítico
 * [Segundo Parcial] RNF02 - Aislamiento por empresa
 */
import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { BaseChartDirective } from 'ng2-charts';
import { ChartConfiguration, ChartData, ChartType } from 'chart.js';
import { AdminShellComponent } from '../../shared/admin-shell/admin-shell';
import { LoaderComponent, AlertComponent } from '../../shared/ui';

@Component({
  selector: 'app-admin-dashboard',
  imports: [CommonModule, FormsModule, AdminShellComponent, BaseChartDirective, LoaderComponent, AlertComponent],
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

  // [Segundo Parcial] CU23, CU24
  preguntaIA = '';
  consultandoIA = false;
  resultadoIA: any = null;
  errorIA = '';
  predicciones: any = null;
  cargandoPred = false;
  predChartData: ChartData<'line'> = { labels: [], datasets: [] };
  predChartType: ChartType = 'line';
  predChartOptions: any = { responsive: true };

  ngOnInit(): void {
    this.cargar();
    this.cargarPredicciones();
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


// [Segundo Parcial] CU23 - Reportes Generativos IA
// [Segundo Parcial] CU24 - Machine Learning Predicciones

  cargarPredicciones(): void {
    this.cargandoPred = true;
    this.http.get<any>('https://menstyle-api-n77g.onrender.com/api/ia/predicciones', { headers: this.headers() }).subscribe({
      next: (res) => {
        this.predicciones = res;
        const labels = (res.historico || []).map((h: any) => h.mes);
        labels.push(res.prediccion?.mes);
        const dataHist = (res.historico || []).map((h: any) => h.ventas);
        const dataPred = Array(dataHist.length).fill(null);
        dataPred.push(res.prediccion?.ventas);
        this.predChartData = {
          labels,
          datasets: [
            { data: dataHist.concat([null]), label: 'Ventas históricas (Bs)', borderColor: '#0a0a0a' },
            { data: dataPred, label: 'Proyección (Bs)', borderColor: '#d97706', borderDash: [5,5] }
          ]
        };
        this.cargandoPred = false;
        this.cdr.detectChanges();
      },
      error: () => { this.cargandoPred = false; this.cdr.detectChanges(); }
    });
  }

  preguntarIA(): void {
    if (!this.preguntaIA.trim()) return;
    this.consultandoIA = true;
    this.errorIA = '';
    this.resultadoIA = null;
    this.http.post<any>('https://menstyle-api-n77g.onrender.com/api/ia/consultar', { pregunta: this.preguntaIA }, { headers: this.headers() }).subscribe({
      next: (res) => {
        this.resultadoIA = res;
        this.consultandoIA = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.errorIA = err?.error?.detail || 'Error al consultar IA';
        this.consultandoIA = false;
        this.cdr.detectChanges();
      }
    });
  }
