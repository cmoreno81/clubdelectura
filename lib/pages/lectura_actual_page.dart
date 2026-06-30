import 'package:flutter/material.dart';

import '../models/dashboard.dart';
import '../services/api_service.dart';

class LecturaActualPage extends StatefulWidget {
  const LecturaActualPage({super.key});

  @override
  State<LecturaActualPage> createState() => _LecturaActualPageState();
}

class _LecturaActualPageState extends State<LecturaActualPage> {
  late Future<Dashboard> dashboardFuture;

  @override
  void initState() {
    super.initState();
    dashboardFuture = ApiService().getDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Dashboard>(
      future: dashboardFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final dashboard = snapshot.data!;
        final lectura = dashboard.lecturaActual;

        return Scaffold(
          appBar: AppBar(title: const Text("📖 Lectura del club")),

          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                lectura.titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              Text(
                "👥 Leyéndolo (${lectura.totalLeyendo})",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (lectura.leyendo.isEmpty)
                const Text("Todavía nadie lo está leyendo."),

              ...lectura.leyendo.map(
                (usuario) => ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: Text(usuario),
                ),
              ),

              const SizedBox(height: 30),

              Text(
                "✅ Finalizado (${lectura.totalFinalizado})",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (lectura.finalizado.isEmpty)
                const Text("Todavía nadie lo ha terminado."),

              ...lectura.finalizado.map(
                (item) => ListTile(
                  leading: const Icon(Icons.star),
                  title: Text(item.usuario),
                  trailing: Text(item.valoracion),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
