import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import 'capitulo_page.dart';
import 'configurar_lectura_page.dart';
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

  final Set<String> _capitulosPlegados = <String>{};

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    future = ApiService().getLecturaCompartida();
  }

  void _alternarCapitulo(String nombre) {
    setState(() {
      if (_capitulosPlegados.contains(nombre)) {
        _capitulosPlegados.remove(nombre);
      } else {
        _capitulosPlegados.add(nombre);
      }
    });
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

        // =====================================================
        // La conversación todavía no existe
        // =====================================================

        if (!lectura.configurada) {
          return Scaffold(
            appBar: AppBar(title: const Text("💬 Lectura compartida")),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.menu_book,
                      size: 80,
                      color: Colors.deepPurple,
                    ),

                    const SizedBox(height: 24),

                    Text(
                      lectura.libro,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "Todavía no existe una conversación para esta lectura oficial.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "La primera persona que empiece el libro puede configurarla para todo el club.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),

                    const SizedBox(height: 40),

                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 56),
                      ),
                      icon: const Icon(Icons.auto_stories),
                      label: const Text("Crear conversación"),
                      onPressed: () async {
                        final creada = await Navigator.push<bool>(
                          context,
                          AppPageRoute(
                            builder: (_) => ConfigurarLecturaPage(
                              libro: lectura.libro,
                              tipo: "OFICIAL",
                            ),
                          ),
                        );

                        if (creada == true) {
                          setState(() {
                            _recargar();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // =====================================================
        // Conversación existente
        // =====================================================

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
                  capitulo: capitulo,
                  plegado: _capitulosPlegados.contains(capitulo.nombre),
                  onTogglePlegado: () {
                    _alternarCapitulo(capitulo.nombre);
                  },
                  onTap: () async {
                    await Navigator.push(
                      context,
                      AppPageRoute(
                        builder: (_) => CapituloPage(
                          libro: lectura.libro,
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
          ),
        );
      },
    );
  }
}
