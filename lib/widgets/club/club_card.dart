import 'package:club_lectura_app/pages/clubvision_menu_page.dart';
import 'package:flutter/material.dart';
import '../../models/dashboard.dart';
import '../../models/estado_club.dart';
import '../../pages/clubvisionVotacionPage.dart';
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
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ClubvisionMenuPage()),
        );

        await onActualizar();
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
                    const SizedBox(height: 20),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: dashboard.clubvision.totalUsuarios == 0
                            ? 0
                            : dashboard.clubvision.votosRecibidos /
                                  dashboard.clubvision.totalUsuarios,
                        minHeight: 10,
                        backgroundColor: Colors.white70,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      '🗳️ ${dashboard.clubvision.votosRecibidos} de ${dashboard.clubvision.totalUsuarios} lectoras han votado',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    if (dashboard.clubvision.votosPendientes > 0)
                      const SizedBox(height: 20),

                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Solo faltan ${dashboard.clubvision.votosPendientes} 💜',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (!haVotado)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final actualizado = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClubvisionVotacionPage(
                                  idVotacion: dashboard.clubvision.idVotacion,
                                ),
                              ),
                            );

                            if (actualizado == true) {
                              await onActualizar();
                            }
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
