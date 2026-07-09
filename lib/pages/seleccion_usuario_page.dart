import 'package:club_lectura_app/widgets/error_view.dart';
import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/usuario_service.dart';
import 'home_page.dart';

class SeleccionUsuarioPage extends StatefulWidget {
  const SeleccionUsuarioPage({super.key});

  @override
  State<SeleccionUsuarioPage> createState() => _SeleccionUsuarioPageState();
}

class _SeleccionUsuarioPageState extends State<SeleccionUsuarioPage> {
  late Future<List<Usuario>> future;

  @override
  void initState() {
    super.initState();
    future = ApiService().getUsuarios();
  }

  Color _color(String nombre) {
    final colors = [
      Colors.deepPurple,
      Colors.pink,
      Colors.blue,
      Colors.teal,
      Colors.orange,
      Colors.indigo,
      Colors.green,
    ];

    return colors[nombre.hashCode.abs() % colors.length];
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+'));

    if (partes.isEmpty) return '?';

    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }

    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  Future<void> _seleccionarUsuario(Usuario usuario) async {
    await UsuarioService().guardarUsuario(usuario.nombre);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FE),
      body: FutureBuilder<List<Usuario>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(
              titulo: "No hemos podido entrar al club",
              mensaje:
                  "No hemos podido cargar la lista de lectoras.\n\n"
                  "Comprueba tu conexión e inténtalo de nuevo.",
              onRetry: () {
                setState(() {
                  future = ApiService().getUsuarios();
                });
              },
            );
          }

          final usuarios = snapshot.data!;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 24),

                const Icon(
                  Icons.auto_stories,
                  size: 72,
                  color: Colors.deepPurple,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Bienvenida al Club",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Elige tu perfil para entrar",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),

                const SizedBox(height: 32),

                ...usuarios.map((u) {
                  final color = _color(u.nombre);

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: color.withOpacity(0.15),
                        child: Text(
                          _iniciales(u.nombre),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      title: Text(
                        u.nombre,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text("Entrar al club"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _seleccionarUsuario(u),
                    ),
                  );
                }),

                const SizedBox(height: 20),

                const Text(
                  "Podrás cambiar de usuaria más adelante desde ajustes.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black45),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
