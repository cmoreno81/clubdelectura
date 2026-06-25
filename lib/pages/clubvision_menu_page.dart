import 'package:flutter/material.dart';

import 'ClubVisionVotacionPage.dart';
import 'clubvision_historial_page.dart';

class ClubvisionMenuPage extends StatelessWidget {
  const ClubvisionMenuPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🎤 Clubvisión"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          _card(
            context,
            icon: Icons.how_to_vote,
            titulo: "Votación",
            subtitulo:
                "Elige la próxima lectura del club",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ClubvisionVotacionPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          _card(
            context,
            icon: Icons.emoji_events,
            titulo: "Resultados",
            subtitulo:
                "Consulta la clasificación",
            onTap: () {},
          ),

          const SizedBox(height: 16),
        _card(
        context,
        icon: Icons.history,
        titulo: "Historial",
        subtitulo:
            "Todas las ediciones",
        onTap: () {

            Navigator.push(

            context,

            MaterialPageRoute(

                builder: (_) =>
                    const ClubvisionHistorialPage(),

            ),
            );
        },
        ),
        ],
      ),
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
        leading: Icon(
          icon,
          size: 34,
          color: Colors.deepPurple,
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitulo),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }
}