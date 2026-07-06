import 'package:flutter/material.dart';
import '../widgets/lectura/capitulo_tile.dart';
import '../models/configuracion_lectura.dart';
import '../services/api_service.dart';
import 'capitulo_page.dart';

class LecturaPage extends StatefulWidget {
  final String libro;

  const LecturaPage({super.key, required this.libro});

  @override
  State<LecturaPage> createState() => _LecturaPageState();
}

class _LecturaPageState extends State<LecturaPage> {
  late Future<ConfiguracionLectura> future;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    future = ApiService().getConfiguracionLectura(libro: widget.libro);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📖 Lectura")),
      body: FutureBuilder<ConfiguracionLectura>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final config = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.menu_book,
                        size: 60,
                        color: Colors.deepPurple,
                      ),

                      const SizedBox(height: 12),

                      Text(
                        widget.libro,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ...config.capitulosDisponibles.map(
                (capitulo) => CapituloTile(
                  capitulo: capitulo,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CapituloPage(
                          libro: widget.libro,
                          capitulo: capitulo.nombre,
                        ),
                      ),
                    );

                    if (!mounted) return;

                    setState(() {
                      _recargar();
                    });
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
