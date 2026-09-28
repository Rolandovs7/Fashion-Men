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
  bool ocultarPassword = true;
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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_heroSuperior(), _formularioInferior(context)],
        ),
      ),
    );
  }

  // Sección oscura de arriba, con el logo y la frase editorial.
  Widget _heroSuperior() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 64, 28, 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.negro, AppTheme.carbon],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.bronce,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'M',
                  style: AppTheme.fuenteTitulo.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'MENSTYLE.',
                style: AppTheme.fuenteTitulo.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            'SASTRERÍA · ESTILO · DISTINCIÓN',
            style: AppTheme.fuenteCuerpo.copyWith(
              color: AppTheme.bronce,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: AppTheme.fuenteTitulo.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w400,
                height: 1.2,
                color: Colors.white,
              ),
              children: [
                const TextSpan(text: 'El arte de vestir\n'),
                TextSpan(
                  text: 'sereno.',
                  style: TextStyle(
                    color: AppTheme.bronce,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Moda masculina atemporal, curada para quienes valoran '
            'la calma y la precisión en cada detalle.',
            style: AppTheme.fuenteCuerpo.copyWith(
              color: AppTheme.grisTextoOscuro,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta blanca de abajo, con el formulario.
  Widget _formularioInferior(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      transform: Matrix4.translationValues(0, -20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Inicio',
                style: AppTheme.fuenteCuerpo.copyWith(
                  color: AppTheme.grisTexto,
                  fontSize: 13,
                ),
              ),
              const Text(' / ', style: TextStyle(color: Colors.black38)),
              Text(
                'Ingresar',
                style: AppTheme.fuenteCuerpo.copyWith(
                  color: AppTheme.negro,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'BIENVENIDO DE NUEVO',
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
            style: AppTheme.fuenteTitulo.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppTheme.negro,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Accede para continuar con tu compra.',
            style: AppTheme.fuenteCuerpo.copyWith(
              color: AppTheme.grisTexto,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),

          _etiqueta('CORREO ELECTRÓNICO', requerido: true),
          const SizedBox(height: 8),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'tu@correo.com'),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _etiqueta('CONTRASEÑA'),
              GestureDetector(
                onTap: () => setState(() => ocultarPassword = !ocultarPassword),
                child: Row(
                  children: [
                    Icon(
                      ocultarPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 16,
                      color: AppTheme.grisTexto,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ocultarPassword ? 'Mostrar' : 'Ocultar',
                      style: AppTheme.fuenteCuerpo.copyWith(
                        color: AppTheme.grisTexto,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: passwordController,
            obscureText: ocultarPassword,
            decoration: const InputDecoration(hintText: '••••••••••••'),
          ),

          if (error.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: cargando ? null : iniciarSesion,
              child: Text(cargando ? 'CARGANDO...' : 'INGRESAR'),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: cargando
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegistroPage()),
                    ),
              child: const Text('¿No tienes cuenta? Regístrate'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _etiqueta(String texto, {bool requerido = false}) {
    return RichText(
      text: TextSpan(
        text: texto,
        style: AppTheme.fuenteCuerpo.copyWith(
          color: AppTheme.negro,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
        children: requerido
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
              ]
            : [],
      ),
    );
  }
}
