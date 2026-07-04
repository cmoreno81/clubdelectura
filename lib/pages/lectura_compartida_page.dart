import 'package:flutter/material.dart';
import 'capitulo_page.dart';
import '../models/lectura_compartida.dart';
import '../services/api_service.dart';
import '../widgets/lectura/capitulo_tile.dart';

class LecturaCompartidaPage extends StatefulWidget {
  const LecturaCompartidaPage({super.key});

  @override
  State<LecturaCompartidaPage> createState() => _LecturaCompartidaPageState();
}

class _LecturaCompartidaPageState extends State<LecturaCompartidaPage> {
  late Future<LecturaCompartida> future;

  @override
  void initState() {
    super.initState();
    future = ApiService().getLecturaCompartida();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LecturaCompartida>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final lectura = snapshot.data!;

        return Scaffold(
          appBar: AppBar(title: const Text("💬 Lectura compartida")),

          body: ListView(
            padding: const EdgeInsets.all(20),

            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.menu_book,
                        size: 60,
                        color: Colors.deepPurple,
                      ),

                      const SizedBox(height: 16),

                      Text(
                        lectura.libro,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "👥 Leyéndolo",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              ...lectura.leyendo.map(
                (u) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.auto_stories),
                    title: Text(u),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "🏁 Finalizado",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              ...lectura.finalizados.map(
                (f) => Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    title: Text(f.usuario),
                    trailing: Text(f.valoracion),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Divider(),

              const SizedBox(height: 16),

              const Text(
                "💬 Conversación",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              const Text(
                "Comenta cada capítulo y comparte tus impresiones con el resto del club.",
                style: TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 18),

              ...lectura.capitulosDisponibles.map(
                (capitulo) => CapituloTile(
                  titulo: capitulo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CapituloPage(
                          libro: lectura.libro,
                          capitulo: capitulo,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
