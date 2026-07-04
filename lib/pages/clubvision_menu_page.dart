import 'package:club_lectura_app/pages/clubvision_mi_voto_page.dart';
import 'package:club_lectura_app/pages/lectura_compartida_page.dart';
import 'package:flutter/material.dart';

import '../models/clubvision.dart';
import '../services/api_service.dart';
import 'ClubVisionVotacionPage.dart';
import 'clubvision_historial_page.dart';
import '../pages/clubvision_gala_page.dart';
import '../pages/lectura_actual_page.dart';
import 'clubvision_como_votaron_page.dart';

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

        return Scaffold(
          appBar: AppBar(title: const Text("🎤 Clubvisión")),

          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ..._opcionesPrincipales(club),

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

  List<Widget> _opcionesPrincipales(ClubvisionData club) {
    switch (club.estado) {
      case "VOTACION":
        return [_opcionVotacion(club)];

      case "RESULTADOS":
        return _opcionesResultados();

      case "LECTURA":
        return _opcionesLectura(club);

      default:
        return [];
    }
  }

  Widget _opcionVotacion(ClubvisionData club) {
    return _card(
      context,
      icon: club.haVotado ? Icons.check_circle : Icons.how_to_vote,
      titulo: club.haVotado ? "Mi voto" : "Votación",
      subtitulo: club.haVotado
          ? "Consulta los libros que elegiste."
          : "Elige la próxima lectura del club",
      onTap: () async {
        if (club.haVotado) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClubvisionMiVotoPage()),
          );

          return;
        }

        final actualizado = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ClubvisionVotacionPage(idVotacion: club.idVotacion),
          ),
        );

        if (!mounted) return;

        if (actualizado == true) {
          setState(() {
            clubvisionFuture = ApiService().getClubvision();
          });
        }
      },
    );
  }

  List<Widget> _opcionesResultados() {
    return [
      _card(
        context,
        icon: Icons.emoji_events,
        titulo: "Gala",
        subtitulo: "Descubre la próxima lectura",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClubvisionGalaPage()),
          );
        },
      ),

      const SizedBox(height: 16),

      _card(
        context,
        icon: Icons.how_to_vote,
        titulo: "Cómo votaron",
        subtitulo: "Descubre las puntuaciones de todas las lectoras",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ClubvisionComoVotaronPage(),
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _opcionesLectura(ClubvisionData club) {
    return [
      _card(
        context,
        icon: Icons.menu_book,
        titulo: "Lectura actual",
        subtitulo: "Comenta la lectura en curso",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LecturaCompartidaPage()),
          );
        },
      ),

      const SizedBox(height: 16),

      _card(
        context,
        icon: Icons.how_to_vote,
        titulo: "Cómo votaron",
        subtitulo: "Consulta todas las puntuaciones",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ClubvisionComoVotaronPage(),
            ),
          );
        },
      ),
    ];
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
