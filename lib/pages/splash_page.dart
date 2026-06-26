import 'package:flutter/material.dart';

import '../services/usuario_service.dart';
import 'home_page.dart';
import 'seleccion_usuario_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    _comprobarUsuario();
  }

  Future<void> _comprobarUsuario() async {
    final usuario = await UsuarioService().obtenerUsuario();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,

      MaterialPageRoute(
        builder: (_) =>
            usuario == null ? const SeleccionUsuarioPage() : const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
