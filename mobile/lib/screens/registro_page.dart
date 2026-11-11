import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU03 - Registrar Usuario
// RF: RF01 - Registrar clientes
// CAPA: Flutter | BACKEND: POST /api/auth/registro
// [Rediseño lote fix] Card centrada sobre degradado, logo y
// campos con iconos, igual que el Login.
// ============================================================
class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthService authService = AuthService();

  bool cargando = false;
  bool ocultarPassword = true;
  String error = '';
  String mensaje = '';

  Future<void> registrar() async {
    setState(() {
      cargando = true;
      error = '';
      mensaje = '';
    });

    try {
      await authService.registrar(
        nombre: nombreController.text.trim(),
        apellido: apellidoController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      setState(() {
        mensaje = 'Cuenta creada correctamente. Ahora puedes iniciar sesión.';
      });

      await Future.delayed(const Duration(milliseconds: 900));

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    apellidoController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
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
                child: Card(
                  elevation: 6,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _logo(),
                        const SizedBox(height: 24),
                        Text(
                          'CREAR CUENTA',
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
                          'Regístrate para comenzar',
                          textAlign: TextAlign.center,
                          style: AppTheme.fuenteTitulo.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.negro,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: nombreController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  hintText: 'Nombre',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: apellidoController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  hintText: 'Apellido',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                            hintText: 'Contraseña',
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
                        if (mensaje.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    mensaje,
                                    style: const TextStyle(color: Colors.green, fontSize: 12.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                            onPressed: cargando ? null : registrar,
                            child: Text(cargando ? 'CREANDO CUENTA...' : 'CREAR CUENTA'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: cargando ? null : () => Navigator.of(context).pop(),
                          child: const Text('¿Ya tienes cuenta? Iniciar sesión'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
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
