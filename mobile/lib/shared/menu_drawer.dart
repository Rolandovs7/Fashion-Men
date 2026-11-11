import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/auth_service.dart';
import '../screens/login_page.dart';

/// ============================================================
/// [Rediseño 2.2] Piezas compartidas del menú hamburguesa
/// (Drawer) para todos los shells: encabezado con avatar, nombre
/// y rol del usuario sobre el negro de marca; títulos de sección
/// como separadores; y "Cerrar sesión" al final en rojo.
/// ============================================================

class DrawerEncabezado extends StatelessWidget {
  final String nombre;
  final String rolEtiqueta;
  final String email;
  final String? marca;

  const DrawerEncabezado({
    super.key,
    required this.nombre,
    required this.rolEtiqueta,
    this.email = '',
    this.marca,
  });

  @override
  Widget build(BuildContext context) {
    final nombreLimpio = nombre.trim();
    final inicial = nombreLimpio.isNotEmpty ? nombreLimpio.characters.first.toUpperCase() : 'U';

    return DrawerHeader(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: AppTheme.negro,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.amarilloMarca.withValues(alpha: 0.35),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.amarilloMarca,
                child: Text(
                  inicial,
                  style: const TextStyle(
                    color: AppTheme.negro,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombreLimpio.isEmpty ? 'Usuario' : nombreLimpio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rolEtiqueta,
                      style: TextStyle(
                        color: AppTheme.amarilloMarca,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    if (email.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            (marca ?? AuthService.instance.nombreEmpresa).toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.28),
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de grupo dentro del Drawer (separador entre secciones).
class DrawerSeccion extends StatelessWidget {
  final String titulo;
  const DrawerSeccion(this.titulo, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        titulo,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.grisTexto,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// "Cerrar sesión" al final del menú, con ícono rojo.
class DrawerCerrarSesion extends StatelessWidget {
  const DrawerCerrarSesion({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    await AuthService.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text(
        'Cerrar sesión',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
      ),
      onTap: () => _cerrarSesion(context),
    );
  }
}

/// Etiqueta legible del rol (usada por los headers del Drawer).
String rolEtiquetaDe(dynamic rol) {
  switch ((rol ?? 'cliente').toString()) {
    case 'superadmin':
      return 'SuperAdmin';
    case 'administrador':
      return 'Administrador';
    default:
      return 'Cliente';
  }
}
