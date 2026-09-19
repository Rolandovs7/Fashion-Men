import { Pipe, PipeTransform } from '@angular/core';

/**
 * Convierte una fecha que viene del backend (string ISO sin timezone,
 * interpretado como UTC) a la zona horaria de Bolivia (America/La_Paz)
 * y la formatea.
 *
 * Uso: {{ pedido.fecha_pedido | fechaBolivia }}
 *      {{ pedido.fecha_pedido | fechaBolivia:'dd/MM/yyyy HH:mm' }}
 */
@Pipe({
  name: 'fechaBolivia',
  standalone: true
})
export class FechaBoliviaPipe implements PipeTransform {
  transform(value: string | Date | null | undefined, formato: string = 'dd/MM/yyyy HH:mm'): string {
    if (!value) return '';

    let fecha: Date;
    if (typeof value === 'string') {
      // Si el string NO termina en Z ni tiene offset, asumimos UTC
      const iso = /Z|[+-]\d{2}:?\d{2}$/.test(value) ? value : value + 'Z';
      fecha = new Date(iso);
    } else {
      fecha = value;
    }

    if (isNaN(fecha.getTime())) return '';

    // Formatear manualmente en zona Bolivia
    const opciones: Intl.DateTimeFormatOptions = {
      timeZone: 'America/La_Paz',
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false
    };

    const partes = new Intl.DateTimeFormat('es-BO', opciones).formatToParts(fecha);
    const get = (tipo: string) => partes.find(p => p.type === tipo)?.value ?? '';

    // Si el formato es el estándar, devolver dd/MM/yyyy HH:mm
    if (formato === 'dd/MM/yyyy HH:mm') {
      return `${get('day')}/${get('month')}/${get('year')} ${get('hour')}:${get('minute')}`;
    }
    if (formato === 'dd/MM/yyyy') {
      return `${get('day')}/${get('month')}/${get('year')}`;
    }
    if (formato === 'HH:mm') {
      return `${get('hour')}:${get('minute')}`;
    }

    // Fallback
    return `${get('day')}/${get('month')}/${get('year')} ${get('hour')}:${get('minute')}`;
  }
}
