import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AdminShellComponent } from '../../shared/admin-shell/admin-shell';
import { EmpresaCrearRequest, EmpresaListado, EmpresaService } from '../../core/services/empresa.service';
import { SuscripcionService, Plan } from '../../core/services/suscripcion.service';
import { AuthService } from '../../core/services/auth.service';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { AlertComponent } from '../../shared/ui';

@Component({
  selector: 'app-admin-empresas',
  standalone: true,
  imports: [CommonModule, FormsModule, AdminShellComponent, AlertComponent],
  templateUrl: './admin-empresas.html'
})
export class AdminEmpresas implements OnInit {
  private empresaService = inject(EmpresaService);
  private suscripcionService = inject(SuscripcionService);
  private authService = inject(AuthService);
  private toast = inject(ToastService);
  private cdr = inject(ChangeDetectorRef);

  rol = '';
  planes: Plan[] = [];
  empresas: EmpresaListado[] = [];
  cargandoEmpresas = false;
  guardando = false;
  error = '';
  form: EmpresaCrearRequest = {
    nombre_empresa: '',
    plan_id: 0,
    admin_nombre: '',
    admin_apellido: '',
    admin_email: '',
    admin_password: ''
  };

  ngOnInit(): void {
    this.authService.obtenerUsuarioActual().subscribe({
      next: u => {
        this.rol = u?.rol || '';
        if (this.esSuperAdmin()) this.cargarEmpresas();
        this.cdr.detectChanges();
      },
      error: () => {}
    });
    this.suscripcionService.listarPlanes().subscribe({
      next: p => {
        this.planes = p;
        if (p.length && !this.form.plan_id) this.form.plan_id = p[0].id;
        this.cdr.detectChanges();
      },
      error: () => {}
    });
  }

  esSuperAdmin(): boolean { return this.rol === 'superadmin'; }

  cargarEmpresas(): void {
    this.cargandoEmpresas = true;
    this.empresaService.listarEmpresas().subscribe({
      next: e => {
        this.empresas = e || [];
        this.cargandoEmpresas = false;
        this.cdr.detectChanges();
      },
      error: err => {
        this.toast.error(err?.error?.detail || 'No se pudo cargar el listado de empresas.');
        this.cargandoEmpresas = false;
        this.cdr.detectChanges();
      }
    });
  }

  guardar(): void {
    if (!this.esSuperAdmin()) { this.toast.error('Solo un superadmin puede crear empresas.'); return; }
    if (!this.form.nombre_empresa?.trim() || !this.form.plan_id) { this.toast.error('Nombre de empresa y plan son obligatorios.'); return; }
    const payload: EmpresaCrearRequest = {
      nombre_empresa: this.form.nombre_empresa.trim(),
      plan_id: Number(this.form.plan_id),
      admin_nombre: this.form.admin_nombre?.trim() || null,
      admin_apellido: this.form.admin_apellido?.trim() || null,
      admin_email: this.form.admin_email?.trim() || null,
      admin_password: this.form.admin_password || null,
    };
    this.guardando = true; this.error = '';
    this.empresaService.crearEmpresa(payload).subscribe({
      next: res => {
        this.toast.exito(res.mensaje || 'Empresa creada correctamente.');
        this.form = { nombre_empresa: '', plan_id: this.planes[0]?.id || 0, admin_nombre: '', admin_apellido: '', admin_email: '', admin_password: '' };
        this.guardando = false;
        this.cargarEmpresas();
        this.cdr.detectChanges();
      },
      error: e => {
        this.error = e?.error?.detail || 'No se pudo crear la empresa.';
        this.toast.error(this.error);
        this.guardando = false; this.cdr.detectChanges();
      }
    });
  }
}
