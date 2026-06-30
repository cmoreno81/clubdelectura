import 'package:flutter/material.dart';
import '../../pages/clubvision_gala_page.dart';
import '../../models/dashboard.dart';
import '../../models/estado_club.dart';
import '../../pages/clubvisionVotacionPage.dart';
import '../../pages/lectura_actual_page.dart';
import 'director_escenas.dart';

class ClubCard extends StatelessWidget {
  final Dashboard dashboard;
  final EstadoClub estadoClub;
  final bool haVotado;
  final Future<void> Function() onActualizar;

  const ClubCard({
    super.key,
    required this.dashboard,
    required this.estadoClub,
    required this.haVotado,
    required this.onActualizar,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        switch (dashboard.clubvision.estado) {
          case "LECTURA":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LecturaActualPage()),
            );
            break;

          case "VOTACION":
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClubvisionVotacionPage(
                  idVotacion: dashboard.clubvision.idVotacion,
                ),
              ),
            );

            await onActualizar();
            break;

          case "RESULTADOS":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClubvisionGalaPage()),
            );
            break;
        }
      },
      child: Card(
        elevation: 4,
        color: estadoClub.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              Column(
                children: [
                  Icon(estadoClub.icono, size: 54, color: estadoClub.iconColor),

                  const SizedBox(height: 12),

                  Text(
                    estadoClub.titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  DirectorEscenas().construir(
                    estado: estadoClub,
                    dashboard: dashboard,
                  ),

                  if (estadoClub.permiteVotar) ...[
                    const SizedBox(height: 24),

                    if (!haVotado)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClubvisionVotacionPage(
                                  idVotacion: dashboard.clubvision.idVotacion,
                                ),
                              ),
                            );

                            await onActualizar();
                          },
                          icon: const Icon(Icons.how_to_vote),
                          label: const Text(
                            "Votar ahora",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      )
                    else
                      const Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 42,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Tu voto ya forma parte de esta historia.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Ahora solo queda esperar al desenlace.",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                  ],

                  if (estadoClub.mostrarGanador) ...[
                    const SizedBox(height: 20),

                    Text(
                      dashboard.clubvision.lectoras.isEmpty
                          ? '🌟 Estreno para todo el club'
                          : '⭐ Ya leído por:\n${dashboard.clubvision.lectoras.join(", ")}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ],
              ),

              if (dashboard.clubvision.estado == "LECTURA" ||
                  dashboard.clubvision.estado == "VOTACION" ||
                  dashboard.clubvision.estado == "RESULTADOS")
                const Positioned(
                  top: 16,
                  right: 16,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 34,
                    color: Colors.black38,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
