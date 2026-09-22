import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/auth_service.dart';
import 'main_shell.dart';
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

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainShell(usuario: usuario)),
      );
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
          // Imagen de fondo
          Image.network(
            'https://images.unsplash.com/photo-1617137968427-85924c800a22?q=80&w=1200',
            fit: BoxFit.cover,
          ),
          // Degradado oscuro encima para que el texto se lea bien
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.black87],
              ),
            ),
          ),
          // Contenido
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  color: Colors.white.withValues(alpha: 0.96),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'MENSTYLE',
                          textAlign: TextAlign.center,
                          style: AppTheme.fuenteTitulo.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 6,
                            color: AppTheme.negro,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Moda masculina a tu estilo',
                          textAlign: TextAlign.center,
                          style: AppTheme.fuenteCuerpo.copyWith(
                            color: AppTheme.grisTexto,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 35),
                        Text(
                          'Iniciar sesión',
                          style: AppTheme.fuenteTitulo.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
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
                        const SizedBox(height: 12),
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
