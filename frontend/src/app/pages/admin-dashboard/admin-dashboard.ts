/**
 * [Segundo Parcial] CU25 - Dashboard analítico
 * [Segundo Parcial] RNF02 - Aislamiento por empresa
 * [Segundo Parcial] CU23 - Reportes Generativos IA
 * [Segundo Parcial] CU24 - Machine Learning Predicciones
 */
import {
  Component,
  OnInit,
  inject,
  ChangeDetectorRef,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { ChartConfiguration, ChartData, ChartType } from 'chart.js';
import { BaseChartDirective } from 'ng2-charts';

import { AdminShellComponent } from '../../shared/admin-shell/admin-shell';
import { LoaderComponent } from '../../shared/ui/loader/loader';
import { AlertComponent } from '../../shared/ui/alert/alert';
import { SuscripcionService } from '../../core/services/suscripcion.service';

@Component({
  selector: 'app-admin-dashboard',
  imports: [
    CommonModule,
    FormsModule,
    AdminShellComponent,
    BaseChartDirective,
    LoaderComponent,
    AlertComponent,
  ],
  templateUrl: './admin-dashboard.html',
})
export class AdminDashboard implements OnInit {
  private http = inject(HttpClient);
  private cdr = inject(ChangeDetectorRef);
  private suscripcionService = inject(SuscripcionService);

  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/reportes';
  private iaUrl = 'https://menstyle-api-n77g.onrender.com/api/ia';

  cargando = true;
  error = '';

  // Restricción por plan: IA/ML solo si el plan lo permite (p.ej. Profesional)
  permiteIA = false;

  kpis: any = null;
  ventasMes: any[] = [];
  ventasSucursal: any[] = [];

  barChartType: ChartType = 'bar';
  barChartData: ChartData<'bar'> = {
    labels: [],
    datasets: [{ data: [], label: 'Ventas por mes (Bs)' }],
  };
  barChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
  };

  pieChartType: ChartType = 'pie';
  pieChartData: ChartData<'pie'> = {
    labels: [],
    datasets: [{ data: [] }],
  };
  pieChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
  };

  // [Segundo Parcial] CU24 - Predicciones ML
  predicciones: any = null;
  cargandoPred = false;
  predChartType: ChartType = 'line';
  predChartData: ChartData<'line'> = {
    labels: [],
    datasets: [],
  };
  predChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
  };

  ngOnInit(): void {
    this.cargar();
    this.suscripcionService.obtenerMiSuscripcion().subscribe({
      next: (s) => {
        const plan = s?.plan;
        this.permiteIA = plan?.permite_ia === true || plan?.nombre === 'Profesional';
        if (this.permiteIA) this.cargarPredicciones();
        this.cdr.detectChanges();
      },
      error: () => {
        this.permiteIA = false;
        this.cdr.detectChanges();
      },
    });
  }

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token') || ''}`,
    });
  }

  cargar(): void {
    this.cargando = true;
    this.error = '';

    this.http.get<any>(`${this.apiUrl}/dashboard`, { headers: this.headers() }).subscribe({
      next: (res) => {
        this.kpis = res;
        this.cdr.detectChanges();
      },
    });

    this.http
      .get<any[]>(`${this.apiUrl}/ventas-por-mes?meses=12`, { headers: this.headers() })
      .subscribe({
        next: (res) => {
          this.ventasMes = res;
          this.barChartData = {
            labels: res.map((r) => r.mes),
            datasets: [{ data: res.map((r) => r.total), label: 'Ventas por mes (Bs)' }],
          };
          this.cdr.detectChanges();
        },
      });

    this.http.get<any[]>(`${this.apiUrl}/ventas-por-sucursal`, { headers: this.headers() }).subscribe({
      next: (res) => {
        this.ventasSucursal = res;
        this.pieChartData = {
          labels: res.map((r) => r.sucursal),
          datasets: [{ data: res.map((r) => r.total_ventas) }],
        };
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.cargando = false;
        this.cdr.detectChanges();
      },
    });
  }

  cargarPredicciones(): void {
    this.cargandoPred = true;
    this.http.get<any>(`${this.iaUrl}/predicciones`, { headers: this.headers() }).subscribe({
      next: (res) => {
        this.predicciones = res;
        const historico = res?.historico || [];
        const pred = res?.prediccion || {};
        const labels = historico.map((h: any) => h.mes);
        labels.push(pred.mes);
        const dataHist = historico.map((h: any) => h.ventas);
        const dataPred = Array(dataHist.length).fill(null);
        dataPred.push(pred.ventas);
        this.predChartData = {
          labels,
          datasets: [
            { data: dataHist.concat([null]), label: 'Ventas históricas (Bs)', borderColor: '#0a0a0a' },
            { data: dataPred, label: 'Proyección (Bs)', borderColor: '#d97706', borderDash: [5, 5] },
          ],
        };
        this.cargandoPred = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.cargandoPred = false;
        this.cdr.detectChanges();
      },
    });
  }
}
