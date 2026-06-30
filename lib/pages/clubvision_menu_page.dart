import 'package:flutter/material.dart';

import '../models/clubvision.dart';
import '../services/api_service.dart';
import 'ClubVisionVotacionPage.dart';
import 'clubvision_historial_page.dart';
import '../pages/clubvision_gala_page.dart';
import '../pages/lectura_actual_page.dart';

class ClubvisionMenuPage extends StatefulWidget {
  const ClubvisionMenuPage({super.key});

  @override
  State<ClubvisionMenuPage> createState() => _ClubvisionMenuPageState();
}

class _ClubvisionMenuPageState extends State<ClubvisionMenuPage> {
  late Future<ClubvisionData> clubvisionFuture;

  @override
  void initState() {
    super.initState();
    clubvisionFuture = ApiService().getClubvision();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ClubvisionData>(
      future: clubvisionFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final club = snapshot.data!;
        final estado = club.estado;

        return Scaffold(
          appBar: AppBar(title: const Text("🎤 Clubvisión")),

          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (estado == "VOTACION")
                _card(
                  context,
                  icon: Icons.how_to_vote,
                  titulo: "Votación",
                  subtitulo: "Elige la próxima lectura del club",
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ClubvisionVotacionPage(idVotacion: club.idVotacion),
                      ),
                    );

                    if (!mounted) return;

                    setState(() {
                      clubvisionFuture = ApiService().getClubvision();
                    });
                  },
                ),

              if (estado == "RESULTADOS")
                _card(
                  context,
                  icon: Icons.emoji_events,
                  titulo: "Gala",
                  subtitulo: "Descubre la próxima lectura",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClubvisionGalaPage(),
                      ),
                    );
                  },
                ),

              if (estado == "LECTURA")
                _card(
                  context,
                  icon: Icons.menu_book,
                  titulo: "Lectura actual",
                  subtitulo: club.ganador,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LecturaActualPage(),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 16),

              _card(
                context,
                icon: Icons.history,
                titulo: "Historial",
                subtitulo: "Todas las ediciones",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClubvisionHistorialPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 34, color: Colors.deepPurple),
        title: Text(
          titulo,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
