import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/auth_service.dart';
import 'main_shell.dart';
import 'admin_catalogo_page.dart';
import 'registro_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthService authService = AuthService();

  bool cargando = false;
  String error = '';

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

      if (authService.esAdministrador) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminCatalogoPage()),
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
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo: sastrería masculina en tonos oscuros.
          Image.network(
            'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?q=80&w=1400',
            fit: BoxFit.cover,
          ),
          // Vignette oscuro para look editorial de revista.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black87, Colors.black54, Colors.black87],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Título fuera de la tarjeta, sobre la imagen.
                    Text(
                      'MENSTYLE',
                      textAlign: TextAlign.center,
                      style: AppTheme.fuenteTitulo.copyWith(
                        fontSize: 44,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 8,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(width: 60, height: 1.4, color: AppTheme.bronce),
                    const SizedBox(height: 10),
                    Text(
                      'SASTRERÍA · ESTILO · DISTINCIÓN',
                      textAlign: TextAlign.center,
                      style: AppTheme.fuenteCuerpo.copyWith(
                        color: AppTheme.bronce,
                        letterSpacing: 3,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Tarjeta translúcida tipo "vidrio esmerilado".
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppTheme.bronce.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Iniciar sesión',
                            textAlign: TextAlign.center,
                            style: AppTheme.fuenteTitulo.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.negro,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          if (error.isNotEmpty) ...[
                            const SizedBox(height: 15),
                            Text(
                              error,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: cargando ? null : iniciarSesion,
                              child: Text(
                                cargando ? 'CARGANDO...' : 'INICIAR SESIÓN',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: cargando
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const RegistroPage(),
                                    ),
                                  ),
                            child: const Text('¿No tienes cuenta? Regístrate'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
