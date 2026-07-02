import 'package:flutter/material.dart';

import '../models/historial_clubvision.dart';
import '../services/api_service.dart';
import '../widgets/error_view.dart';

class ClubvisionHistorialPage extends StatefulWidget {
  const ClubvisionHistorialPage({super.key});

  @override
  State<ClubvisionHistorialPage> createState() =>
      _ClubvisionHistorialPageState();
}

class _ClubvisionHistorialPageState extends State<ClubvisionHistorialPage> {
  late Future<List<HistorialClubvision>> future;

  @override
  void initState() {
    super.initState();

    future = ApiService().getHistorialClubvision();
  }

  String _mes(String fecha) {
    try {
      final partes = fecha.split("-");

      final anio = int.parse(partes[0]);
      final mes = int.parse(partes[1]);

      const meses = [
        "Enero",
        "Febrero",
        "Marzo",
        "Abril",
        "Mayo",
        "Junio",
        "Julio",
        "Agosto",
        "Septiembre",
        "Octubre",
        "Noviembre",
        "Diciembre",
      ];

      return "${meses[mes - 1]} $anio";
    } catch (_) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📜 Historial")),

      body: FutureBuilder<List<HistorialClubvision>>(
        future: future,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(
              onRetry: () {
                setState(() {
                  future = ApiService().getHistorialClubvision();
                });
              },
            );
          }

          final historial = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),

            itemCount: historial.length,

            itemBuilder: (context, index) {
              final h = historial[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),

                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        _mes(h.mes),

                        style: const TextStyle(
                          fontSize: 22,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text("🥇 ${h.ganadora}"),

                      Text("⭐ ${h.puntos} puntos"),

                      const SizedBox(height: 8),

                      Text("🥈 ${h.segunda}"),

                      Text("🥉 ${h.tercera}"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
