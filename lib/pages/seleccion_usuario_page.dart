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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📚 Bienvenida')),

      body: FutureBuilder<List<Usuario>>(
        future: future,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('📚 Bienvenida')),
              body: ErrorView(
                titulo: "No hemos podido entrar al club",
                mensaje:
                    "No hemos podido cargar la lista de lectoras.\n\n"
                    "Comprueba tu conexión e inténtalo de nuevo.",
                onRetry: () {
                  setState(() {
                    future = ApiService().getUsuarios();
                  });
                },
              ),
            );
          }

          final usuarios = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),

            children: [
              const Text(
                '¿Quién eres?',

                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 24),

              ...usuarios.map((u) {
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),

                    title: Text(u.nombre),

                    subtitle: Text(u.email),

                    trailing: const Icon(Icons.chevron_right),

                    onTap: () async {
                      await UsuarioService().guardarUsuario(u.nombre);

                      if (!mounted) {
                        return;
                      }

                      Navigator.pushReplacement(
                        context,

                        MaterialPageRoute(builder: (_) => const HomePage()),
                      );
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
