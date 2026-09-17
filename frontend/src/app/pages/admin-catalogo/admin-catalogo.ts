import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CategoriasService, Categoria } from '../../core/services/categorias.service';
import { ProductosService, Producto } from '../../core/services/productos.service';
import { VariantesService, Variante, Talla, Color } from '../../core/services/variantes.service';
import { SucursalesService, Sucursal } from '../../core/services/sucursales.service';
import { ProveedoresService, Proveedor } from '../../core/services/proveedores.service';
import { TemporadasService, Temporada } from '../../core/services/temporadas.service';
import { ColeccionesService, Coleccion } from '../../core/services/colecciones.service';
import { TiposPrendaService, TipoPrenda } from '../../core/services/tipos-prenda.service';
import { MarcasService, Marca } from '../../core/services/marcas.service';
import { DescuentosService, Descuento } from '../../core/services/descuentos.service';
import { AdminShellComponent } from '../../shared/admin-shell/admin-shell';

type Pestana = 'categorias' | 'productos' | 'variantes' | 'sucursales' | 'proveedores' | 'temporadas' | 'colecciones' | 'tallas' | 'colores' | 'tipos-prenda' | 'marcas' | 'descuentos';

// ============================================================
// TRAZABILIDAD MENSTYLE — Ciclo de Vida #2 (Administrar Catálogo)
// CAPA: Angular | PANTALLA: pages/admin-catalogo/admin-catalogo.ts
// Ruta protegida por adminGuard (core/guards/auth.guard.ts).
//
// CU07 Productos      | RF04 | api/routes/products.py       | crear/editar/desactivar
// CU08 Tipo de Prenda  | RF: pendiente de confirmar | api/routes/garment_types.py | crear/desactivar (sin editar)
// CU09 Descuentos      | RF: pendiente de confirmar | api/routes/discounts.py     | crear/desactivar (sin editar)
// CU10 Marcas          | RF: pendiente de confirmar | api/routes/brands.py        | crear/desactivar (sin editar)
// CU11 Tallas          | RF05 | api/routes/sizes.py          | crear/desactivar (sin editar; backend sí soporta PUT)
// CU12 Colores         | RF05 | api/routes/colors.py         | crear/desactivar (sin editar; backend sí soporta PUT)
// CU14 Admin. Catálogo | RF04/RF05/RF07 (agregado de los anteriores)
// CU16 Categorías      | RF05 | api/routes/categories.py     | crear/editar/desactivar
// CU17 Sucursales      | RF03 | api/routes/branches.py       | crear/editar/desactivar
// CU26 Proveedores     | RF06 | api/routes/suppliers.py      | crear/desactivar (sin editar; backend sí soporta PUT)
// CU27 Temporadas      | RF23 | api/routes/seasons.py        | crear/desactivar (sin editar; backend sí soporta PUT)
// CU28 Colecciones     | RF23 | api/routes/collections.py    | crear/desactivar (sin editar; backend sí soporta PUT)
// ============================================================
@Component({
  selector: 'app-admin-catalogo',
  imports: [CommonModule, FormsModule, AdminShellComponent],
  templateUrl: './admin-catalogo.html',
  styleUrl: './admin-catalogo.css'
})
export class AdminCatalogo implements OnInit {
  private categoriasService = inject(CategoriasService);
  private productosService = inject(ProductosService);
  private variantesService = inject(VariantesService);
  private sucursalesService = inject(SucursalesService);
  private proveedoresService = inject(ProveedoresService);
  private temporadasService = inject(TemporadasService);
  private coleccionesService = inject(ColeccionesService);
  private tiposPrendaService = inject(TiposPrendaService);
  private marcasService = inject(MarcasService);
  private descuentosService = inject(DescuentosService);
  private cdr = inject(ChangeDetectorRef);

  pestana: Pestana = 'categorias';

  categorias: Categoria[] = [];
  productos: Producto[] = [];
  tallas: Talla[] = [];
  colores: Color[] = [];
  variantesDelProducto: Variante[] = [];
  sucursales: Sucursal[] = [];
  proveedores: Proveedor[] = [];
  temporadas: Temporada[] = [];
  colecciones: Coleccion[] = [];
  tiposPrenda: TipoPrenda[] = [];
  marcas: Marca[] = [];
  descuentos: Descuento[] = [];

  productoSeleccionadoId: number | null = null;

  // Estado de edición (null = modo "crear")
  categoriaEditandoId: number | null = null;
  productoEditandoId: number | null = null;
  sucursalEditandoId: number | null = null;

  // Formularios
  nuevaCategoria = { nombre: '', descripcion: '' };
  nuevoProducto = {
    nombre: '', descripcion: '', precio: 0, categoria_id: 0,
    proveedor_id: 0, temporada_id: 0, coleccion_id: 0,
    tipo_prenda_id: 0, marca_id: 0, descuento_id: 0
  };
  nuevaVariante = { talla_id: 0, color_id: 0 };
  nuevaSucursal = { nombre: '', direccion: '', ciudad: '', telefono: '' };
  nuevoProveedor = { nombre: '', contacto: '', telefono: '', email: '', direccion: '' };
  nuevaTemporada = { nombre: '', descripcion: '' };
  nuevaColeccion = { nombre: '', descripcion: '' };
  nuevaTalla = { nombre: '' };
  nuevoColor = { nombre: '', codigo_hex: '#000000' };
  nuevoTipoPrenda = { nombre: '', descripcion: '' };
  nuevaMarca = { nombre: '', descripcion: '' };
  nuevoDescuento = { nombre: '', porcentaje: 0, fecha_inicio: '', fecha_fin: '' };

  cargando = false;
  guardando = false;
  error = '';
  mensaje = '';

  ngOnInit(): void {
    this.cargarTodo();
  }

  cambiarPestana(pestana: Pestana): void {
    this.pestana = pestana;
    this.error = '';
    this.mensaje = '';
  }

  cargarTodo(): void {
    this.cargando = true;

    this.categoriasService.listar(false).subscribe({
      next: (categorias) => {
        this.categorias = categorias;
        this.cdr.detectChanges();
      }
    });

    this.productosService.listar().subscribe({
      next: (productos) => {
        this.productos = productos;
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.cargando = false;
      }
    });

    this.variantesService.listarTallas().subscribe({ next: (t) => (this.tallas = t) });
    this.variantesService.listarColores().subscribe({ next: (c) => (this.colores = c) });

    this.sucursalesService.listar(false).subscribe({
      next: (sucursales) => {
        this.sucursales = sucursales;
        this.cdr.detectChanges();
      }
    });

    this.proveedoresService.listar(false).subscribe({
      next: (proveedores) => {
        this.proveedores = proveedores;
        this.cdr.detectChanges();
      }
    });

    this.temporadasService.listar(false).subscribe({
      next: (temporadas) => {
        this.temporadas = temporadas;
        this.cdr.detectChanges();
      }
    });

    this.coleccionesService.listar(false).subscribe({
      next: (colecciones) => {
        this.colecciones = colecciones;
        this.cdr.detectChanges();
      }
    });

    this.tiposPrendaService.listar(false).subscribe({
      next: (tipos) => {
        this.tiposPrenda = tipos;
        this.cdr.detectChanges();
      }
    });

    this.marcasService.listar(false).subscribe({
      next: (marcas) => {
        this.marcas = marcas;
        this.cdr.detectChanges();
      }
    });

    this.descuentosService.listar(false).subscribe({
      next: (descuentos) => {
        this.descuentos = descuentos;
        this.cdr.detectChanges();
      }
    });
  }

  // ----- Categorías -----
  editarCategoria(categoria: Categoria): void {
    this.categoriaEditandoId = categoria.id;
    this.nuevaCategoria = { nombre: categoria.nombre, descripcion: categoria.descripcion || '' };
    this.error = '';
    this.mensaje = '';
  }

  cancelarEdicionCategoria(): void {
    this.categoriaEditandoId = null;
    this.nuevaCategoria = { nombre: '', descripcion: '' };
  }

  guardarCategoria(): void {
    if (!this.nuevaCategoria.nombre.trim()) {
      this.error = 'El nombre de la categoría es obligatorio.';
      return;
    }

    this.guardando = true;
    this.error = '';

    const datos = {
      nombre: this.nuevaCategoria.nombre.trim(),
      descripcion: this.nuevaCategoria.descripcion.trim() || null
    };

    const peticion = this.categoriaEditandoId
      ? this.categoriasService.actualizar(this.categoriaEditandoId, datos)
      : this.categoriasService.crear(datos);

    peticion.subscribe({
      next: (categoria) => {
        if (this.categoriaEditandoId) {
          this.categorias = this.categorias.map(c => c.id === categoria.id ? categoria : c);
        } else {
          this.categorias = [...this.categorias, categoria];
        }
        this.cancelarEdicionCategoria();
        this.guardando = false;
        this.mensaje = this.categoriaEditandoId ? 'Categoría actualizada correctamente.' : 'Categoría creada correctamente.';
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.guardando = false;
        this.error = error.error?.detail || 'No se pudo guardar la categoría.';
        this.cdr.detectChanges();
      }
    });
  }

  eliminarCategoria(categoria: Categoria): void {
    if (!confirm(`¿Desactivar la categoría "${categoria.nombre}"?`)) return;

    this.categoriasService.eliminar(categoria.id).subscribe({
      next: (actualizada) => {
        this.categorias = this.categorias.map(c => c.id === actualizada.id ? actualizada : c);
        this.mensaje = 'Categoría desactivada.';
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'No se pudo desactivar la categoría.';
        this.cdr.detectChanges();
      }
    });
  }

  // ----- Productos -----
  editarProducto(producto: Producto): void {
    this.productoEditandoId = producto.id;
    this.nuevoProducto = {
      nombre: producto.nombre,
      descripcion: producto.descripcion || '',
      precio: producto.precio,
      categoria_id: producto.categoria_id,
      proveedor_id: producto.proveedor_id || 0,
      temporada_id: producto.temporada_id || 0,
      coleccion_id: producto.coleccion_id || 0,
      tipo_prenda_id: producto.tipo_prenda_id || 0,
      marca_id: producto.marca_id || 0,
      descuento_id: producto.descuento_id || 0
    };
    this.error = '';
    this.mensaje = '';
  }

  cancelarEdicionProducto(): void {
    this.productoEditandoId = null;
    this.nuevoProducto = {
      nombre: '', descripcion: '', precio: 0, categoria_id: 0,
      proveedor_id: 0, temporada_id: 0, coleccion_id: 0,
      tipo_prenda_id: 0, marca_id: 0, descuento_id: 0
    };
  }

  guardarProducto(): void {
    if (!this.nuevoProducto.nombre.trim() || !this.nuevoProducto.categoria_id || this.nuevoProducto.precio <= 0) {
      this.error = 'Completa nombre, categoría y un precio válido.';
      return;
    }

    this.guardando = true;
    this.error = '';

    const datos = {
      nombre: this.nuevoProducto.nombre.trim(),
      descripcion: this.nuevoProducto.descripcion.trim() || null,
      precio: this.nuevoProducto.precio,
      categoria_id: Number(this.nuevoProducto.categoria_id),
      proveedor_id: this.nuevoProducto.proveedor_id ? Number(this.nuevoProducto.proveedor_id) : null,
      temporada_id: this.nuevoProducto.temporada_id ? Number(this.nuevoProducto.temporada_id) : null,
      coleccion_id: this.nuevoProducto.coleccion_id ? Number(this.nuevoProducto.coleccion_id) : null,
      tipo_prenda_id: this.nuevoProducto.tipo_prenda_id ? Number(this.nuevoProducto.tipo_prenda_id) : null,
      marca_id: this.nuevoProducto.marca_id ? Number(this.nuevoProducto.marca_id) : null,
      descuento_id: this.nuevoProducto.descuento_id ? Number(this.nuevoProducto.descuento_id) : null
    };

    const peticion = this.productoEditandoId
      ? this.productosService.actualizar(this.productoEditandoId, datos)
      : this.productosService.crear(datos);

    peticion.subscribe({
      next: (producto) => {
        if (this.productoEditandoId) {
          this.productos = this.productos.map(p => p.id === producto.id ? producto : p);
        } else {
          this.productos = [...this.productos, producto];
        }
        this.cancelarEdicionProducto();
        this.guardando = false;
        this.mensaje = this.productoEditandoId ? 'Producto actualizado correctamente.' : 'Producto creado correctamente.';
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.guardando = false;
        this.error = error.error?.detail || 'No se pudo guardar el producto.';
        this.cdr.detectChanges();
      }
    });
  }

  eliminarProducto(producto: Producto): void {
    if (!confirm(`¿Desactivar el producto "${producto.nombre}"?`)) return;

    this.productosService.eliminar(producto.id).subscribe({
      next: () => {
        this.productos = this.productos.map(p =>
          p.id === producto.id ? { ...p, activo: false } : p
        );
        this.mensaje = 'Producto desactivado.';
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'No se pudo desactivar el producto.';
        this.cdr.detectChanges();
      }
    });
  }

  nombreCategoria(categoriaId: number): string {
    return this.categorias.find(c => c.id === categoriaId)?.nombre ?? '—';
  }

  nombreProveedor(id?: number | null): string {
    if (!id) return '—';
    return this.proveedores.find(p => p.id === id)?.nombre ?? '—';
  }

  nombreTemporada(id?: number | null): string {
    if (!id) return '—';
    return this.temporadas.find(t => t.id === id)?.nombre ?? '—';
  }

  nombreColeccion(id?: number | null): string {
    if (!id) return '—';
    return this.colecciones.find(c => c.id === id)?.nombre ?? '—';
  }

  // ----- Variantes -----
  seleccionarProducto(productoId: number): void {
    this.productoSeleccionadoId = productoId;
    this.error = '';
    this.mensaje = '';
    this.cargarVariantesDelProducto();
  }

  cargarVariantesDelProducto(): void {
    if (!this.productoSeleccionadoId) return;

    this.variantesService.listarPorProducto(this.productoSeleccionadoId).subscribe({
      next: (variantes) => {
        this.variantesDelProducto = variantes;
        this.cdr.detectChanges();
      },
      error: () => {
        this.variantesDelProducto = [];
        this.cdr.detectChanges();
      }
    });
  }

  crearVariante(): void {
    if (!this.productoSeleccionadoId || !this.nuevaVariante.talla_id || !this.nuevaVariante.color_id) {
      this.error = 'Selecciona producto, talla y color.';
      return;
    }

    this.guardando = true;
    this.error = '';

    this.variantesService.crear({
      producto_id: this.productoSeleccionadoId,
      talla_id: Number(this.nuevaVariante.talla_id),
      color_id: Number(this.nuevaVariante.color_id)
    }).subscribe({
      next: () => {
        this.guardando = false;
        this.mensaje = 'Variante creada correctamente.';
        this.nuevaVariante = { talla_id: 0, color_id: 0 };
        this.cargarVariantesDelProducto();
      },
      error: (error) => {
        this.guardando = false;
        this.error = error.error?.detail || 'No se pudo crear la variante.';
        this.cdr.detectChanges();
      }
    });
  }

  // ----- Sucursales -----
  editarSucursal(sucursal: Sucursal): void {
    this.sucursalEditandoId = sucursal.id;
    this.nuevaSucursal = {
      nombre: sucursal.nombre,
      direccion: sucursal.direccion,
      ciudad: sucursal.ciudad,
      telefono: sucursal.telefono || ''
    };
    this.error = '';
    this.mensaje = '';
  }

  cancelarEdicionSucursal(): void {
    this.sucursalEditandoId = null;
    this.nuevaSucursal = { nombre: '', direccion: '', ciudad: '', telefono: '' };
  }

  guardarSucursal(): void {
    if (!this.nuevaSucursal.nombre.trim() || !this.nuevaSucursal.direccion.trim() || !this.nuevaSucursal.ciudad.trim()) {
      this.error = 'Completa nombre, dirección y ciudad de la sucursal.';
      return;
    }

    this.guardando = true;
    this.error = '';

    const datos = {
      nombre: this.nuevaSucursal.nombre.trim(),
      direccion: this.nuevaSucursal.direccion.trim(),
      ciudad: this.nuevaSucursal.ciudad.trim(),
      telefono: this.nuevaSucursal.telefono.trim() || null
    };

    const peticion = this.sucursalEditandoId
      ? this.sucursalesService.actualizar(this.sucursalEditandoId, datos)
      : this.sucursalesService.crear(datos);

    peticion.subscribe({
      next: (sucursal) => {
        if (this.sucursalEditandoId) {
          this.sucursales = this.sucursales.map(s => s.id === sucursal.id ? sucursal : s);
        } else {
          this.sucursales = [...this.sucursales, sucursal];
        }
        this.cancelarEdicionSucursal();
        this.guardando = false;
        this.mensaje = this.sucursalEditandoId ? 'Sucursal actualizada correctamente.' : 'Sucursal creada correctamente.';
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.guardando = false;
        this.error = error.error?.detail || 'No se pudo guardar la sucursal.';
        this.cdr.detectChanges();
      }
    });
  }

  eliminarSucursal(sucursal: Sucursal): void {
    if (!confirm(`¿Desactivar la sucursal "${sucursal.nombre}"?`)) return;

    this.sucursalesService.eliminar(sucursal.id).subscribe({
      next: (actualizada) => {
        this.sucursales = this.sucursales.map(s => s.id === actualizada.id ? actualizada : s);
        this.mensaje = 'Sucursal desactivada.';
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'No se pudo desactivar la sucursal.';
        this.cdr.detectChanges();
      }
    });
  }

  // ----- Proveedores -----
  crearProveedor(): void {
    if (!this.nuevoProveedor.nombre.trim()) {
      this.error = 'El nombre del proveedor es obligatorio.';
      return;
    }

    this.guardando = true;
    this.error = '';

    this.proveedoresService.crear({
      nombre: this.nuevoProveedor.nombre.trim(),
      contacto: this.nuevoProveedor.contacto.trim() || null,
      telefono: this.nuevoProveedor.telefono.trim() || null,
      email: this.nuevoProveedor.email.trim() || null,
      direccion: this.nuevoProveedor.direccion.trim() || null
    }).subscribe({
      next: (proveedor) => {
        this.proveedores = [...this.proveedores, proveedor];
        this.nuevoProveedor = { nombre: '', contacto: '', telefono: '', email: '', direccion: '' };
        this.guardando = false;
        this.mensaje = 'Proveedor creado correctamente.';
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.guardando = false;
        this.error = error.error?.detail || 'No se pudo crear el proveedor.';
        this.cdr.detectChanges();
      }
    });
  }

  eliminarProveedor(proveedor: Proveedor): void {
    if (!confirm(`¿Desactivar el proveedor "${proveedor.nombre}"?`)) return;

    this.proveedoresService.eliminar(proveedor.id).subscribe({
      next: (actualizado) => {
        this.proveedores = this.proveedores.map(p => p.id === actualizado.id ? actualizado : p);
        this.mensaje = 'Proveedor desactivado.';
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'No se pudo desactivar el proveedor.';
        this.cdr.detectChanges();
      }
    });
  }

  // ----- Temporadas -----
  crearTemporada(): void {
    if (!this.nuevaTemporada.nombre.trim()) {
      this.error = 'El nombre de la temporada es obligatorio.';
      return;
    }

    this.guardando = true;
    this.error = '';

    this.temporadasService.crear({
      nombre: this.nuevaTemporada.nombre.trim(),
      descripcion: this.nuevaTemporada.descripcion.trim() || null
    }).subscribe({
      next: (temporada) => {
        this.temporadas = [...this.temporadas, temporada];
        this.nuevaTemporada = { nombre: '', descripcion: '' };
        this.guardando = false;
        this.mensaje = 'Temporada creada correctamente.';
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.guardando = false;
        this.error = error.error?.detail || 'No se pudo crear la temporada.';
        this.cdr.detectChanges();
      }
    });
  }

  eliminarTemporada(temporada: Temporada): void {
    if (!confirm(`¿Desactivar la temporada "${temporada.nombre}"?`)) return;

    this.temporadasService.eliminar(temporada.id).subscribe({
      next: (actualizada) => {
        this.temporadas = this.temporadas.map(t => t.id === actualizada.id ? actualizada : t);
        this.mensaje = 'Temporada desactivada.';
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'No se pudo desactivar la temporada.';
        this.cdr.detectChanges();
      }
    });
  }

  // ----- Colecciones -----
  crearColeccion(): void {
    if (!this.nuevaColeccion.nombre.trim()) {
      this.error = 'El nombre de la colección es obligatorio.';
      return;
    }

    this.guardando = true;
    this.error = '';

    this.coleccionesService.crear({
      nombre: this.nuevaColeccion.nombre.trim(),
      descripcion: this.nuevaColeccion.descripcion.trim() || null
    }).subscribe({
      next: (coleccion) => {
        this.colecciones = [...this.colecciones, coleccion];
        this.nuevaColeccion = { nombre: '', descripcion: '' };
        this.guardando = false;
        this.mensaje = 'Colección creada correctamente.';
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.guardando = false;
        this.error = error.error?.detail || 'No se pudo crear la colección.';
        this.cdr.detectChanges();
      }
    });
  }

  eliminarColeccion(coleccion: Coleccion): void {
    if (!confirm(`¿Desactivar la colección "${coleccion.nombre}"?`)) return;

    this.coleccionesService.eliminar(coleccion.id).subscribe({
      next: (actualizada) => {
        this.colecciones = this.colecciones.map(c => c.id === actualizada.id ? actualizada : c);
        this.mensaje = 'Colección desactivada.';
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'No se pudo desactivar la colección.';
        this.cdr.detectChanges();
      }
    });
  }

  // ----- Tallas -----
  crearTalla(): void {
    if (!this.nuevaTalla.nombre.trim()) {
      this.error = 'El nombre de la talla es obligatorio.';
      return;
    }

    this.guardando = true;
    this.error = '';

    this.variantesService.crearTalla(this.nuevaTalla.nombre.trim()).subscribe({
      next: (talla) => {
        this.tallas = [...this.tallas, talla];
        this.nuevaTalla = { nombre: '' };
        this.guardando = false;
        this.mensaje = 'Talla creada correctamente.';
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.guardando = false;
        this.error = error.error?.detail || 'No se pudo crear la talla.';
        this.cdr.detectChanges();
      }
    });
  }

  eliminarTalla(talla: Talla): void {
    if (!confirm(`¿Desactivar la talla "${talla.nombre}"?`)) return;

    this.variantesService.eliminarTalla(talla.id).subscribe({
      next: (actualizada) => {
        this.tallas = this.tallas.map(t => t.id === actualizada.id ? actualizada : t);
        this.mensaje = 'Talla desactivada.';
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'No se pudo desactivar la talla.';
        this.cdr.detectChanges();
      }
    });
  }

  // ----- Colores -----
  crearColor(): void {
    if (!this.nuevoColor.nombre.trim()) {
      this.error = 'El nombre del color es obligatorio.';
      return;
    }

    this.guardando = true;
    this.error = '';

    this.variantesService.crearColor(this.nuevoColor.nombre.trim(), this.nuevoColor.codigo_hex).subscribe({
      next: (color) => {
        this.colores = [...this.colores, color];
        this.nuevoColor = { nombre: '', codigo_hex: '#000000' };
        this.guardando = false;
        this.mensaje = 'Color creado correctamente.';
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.guardando = false;
        this.error = error.error?.detail || 'No se pudo crear el color.';
        this.cdr.detectChanges();
      }
    });
  }

  eliminarColor(color: Color): void {
    if (!confirm(`¿Desactivar el color "${color.nombre}"?`)) return;

    this.variantesService.eliminarColor(color.id).subscribe({
      next: (actualizado) => {
        this.colores = this.colores.map(c => c.id === actualizado.id ? actualizado : c);
        this.mensaje = 'Color desactivado.';
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'No se pudo desactivar el color.';
        this.cdr.detectChanges();
      }
    });
  }

  // ----- Tipo de prenda -----
  crearTipoPrenda(): void {
    if (!this.nuevoTipoPrenda.nombre.trim()) {
      this.error = 'El nombre del tipo de prenda es obligatorio.';
      return;
    }

    this.guardando = true;
    this.error = '';

    this.tiposPrendaService.crear(
      this.nuevoTipoPrenda.nombre.trim(),
      this.nuevoTipoPrenda.descripcion.trim() || null
    ).subscribe({
      next: (tipo) => {
        this.tiposPrenda = [...this.tiposPrenda, tipo];
        this.nuevoTipoPrenda = { nombre: '', descripcion: '' };
        this.guardando = false;
        this.mensaje = 'Tipo de prenda creado correctamente.';
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.guardando = false;
        this.error = error.error?.detail || 'No se pudo crear el tipo de prenda.';
        this.cdr.detectChanges();
      }
    });
  }

  eliminarTipoPrenda(tipo: TipoPrenda): void {
    if (!confirm(`¿Desactivar el tipo de prenda "${tipo.nombre}"?`)) return;

    this.tiposPrendaService.eliminar(tipo.id).subscribe({
      next: (actualizado) => {
        this.tiposPrenda = this.tiposPrenda.map(t => t.id === actualizado.id ? actualizado : t);
        this.mensaje = 'Tipo de prenda desactivado.';
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'No se pudo desactivar el tipo de prenda.';
        this.cdr.detectChanges();
      }
    });
  }

  // ----- Marcas -----
  crearMarca(): void {
    if (!this.nuevaMarca.nombre.trim()) {
      this.error = 'El nombre de la marca es obligatorio.';
      return;
    }

    this.guardando = true;
    this.error = '';

    this.marcasService.crear(
      this.nuevaMarca.nombre.trim(),
      this.nuevaMarca.descripcion.trim() || null
    ).subscribe({
      next: (marca) => {
        this.marcas = [...this.marcas, marca];
        this.nuevaMarca = { nombre: '', descripcion: '' };
        this.guardando = false;
        this.mensaje = 'Marca creada correctamente.';
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.guardando = false;
        this.error = error.error?.detail || 'No se pudo crear la marca.';
        this.cdr.detectChanges();
      }
    });
  }

  eliminarMarca(marca: Marca): void {
    if (!confirm(`¿Desactivar la marca "${marca.nombre}"?`)) return;

    this.marcasService.eliminar(marca.id).subscribe({
      next: (actualizada) => {
        this.marcas = this.marcas.map(m => m.id === actualizada.id ? actualizada : m);
        this.mensaje = 'Marca desactivada.';
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'No se pudo desactivar la marca.';
        this.cdr.detectChanges();
      }
    });
  }

  // ----- Descuentos -----
  crearDescuento(): void {
    if (!this.nuevoDescuento.nombre.trim() || this.nuevoDescuento.porcentaje <= 0 || this.nuevoDescuento.porcentaje > 100) {
      this.error = 'Completa el nombre y un porcentaje válido (1-100).';
      return;
    }

    this.guardando = true;
    this.error = '';

    this.descuentosService.crear({
      nombre: this.nuevoDescuento.nombre.trim(),
      porcentaje: this.nuevoDescuento.porcentaje,
      fecha_inicio: this.nuevoDescuento.fecha_inicio || null,
      fecha_fin: this.nuevoDescuento.fecha_fin || null
    }).subscribe({
      next: (descuento) => {
        this.descuentos = [...this.descuentos, descuento];
        this.nuevoDescuento = { nombre: '', porcentaje: 0, fecha_inicio: '', fecha_fin: '' };
        this.guardando = false;
        this.mensaje = 'Descuento creado correctamente.';
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.guardando = false;
        this.error = error.error?.detail || 'No se pudo crear el descuento.';
        this.cdr.detectChanges();
      }
    });
  }

  eliminarDescuento(descuento: Descuento): void {
    if (!confirm(`¿Desactivar el descuento "${descuento.nombre}"?`)) return;

    this.descuentosService.eliminar(descuento.id).subscribe({
      next: (actualizado) => {
        this.descuentos = this.descuentos.map(d => d.id === actualizado.id ? actualizado : d);
        this.mensaje = 'Descuento desactivado.';
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'No se pudo desactivar el descuento.';
        this.cdr.detectChanges();
      }
    });
  }
}
