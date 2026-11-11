import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'admin_main_shell.dart';
import 'main_shell.dart';
import 'registro_page.dart';

class LoginPage extends StatefulWidget {
  /// [Fix 1.1 - Logout bucle] true mientras existe un LoginPage montado.
  /// ApiClient lo consulta para no apilar varias pantallas de Login
  /// cuando varios 401 llegan casi simultáneos.
  static bool abierto = false;

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthService authService = AuthService();

  bool cargando = false;
  bool ocultarPassword = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    LoginPage.abierto = true;
  }

  @override
  void dispose() {
    LoginPage.abierto = false;
    // Al cerrarse el Login (login exitoso o logout) se rehabilita la
    // redirección automática ante 401 de ApiClient.
    ApiClient.liberarRedireccionLogin();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> iniciarSesion() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      await authService.login(
        emailController.text.trim(),
        passwordController.text,
      );

      final usuario = await authService.obtenerUsuarioActual();

      if (!mounted) return;

      if (authService.tieneAccesoAdmin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => AdminMainShell(usuario: usuario)),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainShell(usuario: usuario)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // [Rediseño lote fix] Fondo con degradado + Card centrada.
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.negro, AppTheme.carbon],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _cardFormulario(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Tarjeta blanca centrada con el formulario de acceso.
  Widget _cardFormulario() {
    return Card(
      elevation: 6,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _logo(),
            const SizedBox(height: 28),
            Text(
              'BIENVENIDO DE NUEVO',
              textAlign: TextAlign.center,
              style: AppTheme.fuenteCuerpo.copyWith(
                color: AppTheme.bronce,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa a tu cuenta',
              textAlign: TextAlign.center,
              style: AppTheme.fuenteTitulo.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: AppTheme.negro,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Accede para continuar con tu compra.',
              textAlign: TextAlign.center,
              style: AppTheme.fuenteCuerpo.copyWith(
                color: AppTheme.grisTexto,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 26),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'tu@correo.com',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              obscureText: ocultarPassword,
              decoration: InputDecoration(
                hintText: '••••••••••••',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: ocultarPassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                  onPressed: () => setState(() => ocultarPassword = !ocultarPassword),
                  icon: Icon(
                    ocultarPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppTheme.grisTexto,
                    size: 20,
                  ),
                ),
              ),
            ),

            if (error.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 22),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: cargando ? null : iniciarSesion,
                child: Text(cargando ? 'CARGANDO...' : 'INGRESAR'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: cargando
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegistroPage()),
                    ),
              child: const Text('¿No tienes cuenta? Regístrate'),
            ),
          ],
        ),
      ),
    );
  }

  // Logo de la marca dentro de la card.
  Widget _logo() {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.negro,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'M',
            style: AppTheme.fuenteTitulo.copyWith(
              color: AppTheme.amarilloMarca,
              fontWeight: FontWeight.w800,
              fontSize: 26,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'MENSTYLE.',
          style: AppTheme.fuenteTitulo.copyWith(
            color: AppTheme.negro,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'SASTRERÍA · ESTILO · DISTINCIÓN',
          style: AppTheme.fuenteCuerpo.copyWith(
            color: AppTheme.bronce,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}
