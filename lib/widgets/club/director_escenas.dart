import 'package:flutter/material.dart';
import '../../models/dashboard.dart';
import '../../models/estado_club.dart';
import 'escenas/escena_votacion.dart';

class DirectorEscenas {
  Widget construir({required EstadoClub estado, required Dashboard dashboard}) {
    switch (estado.contenido) {
      case ContenidoClub.preparando:
        return const Column(
          children: [
            Text(
              "La próxima lectura",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Muy pronto conoceremos las candidatas.",
              textAlign: TextAlign.center,
            ),
          ],
        );

      case ContenidoClub.candidatas:
        return EscenaVotacion(
          totalCandidatas: dashboard.clubvision.totalCandidatas,
        );

      case ContenidoClub.ganador:
        return Text(
          dashboard.clubvision.mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        );

      case ContenidoClub.lectura:
        final lectura = dashboard.lecturaActual;

        return Column(
          children: [
            const SizedBox(height: 10),

            Text(
              lectura.titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            if (lectura.comentarios > 0) ...[
              Text(
                "💬 ${lectura.comentarios} comentarios · ❤️ ${lectura.likes}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              if (lectura.ultimaActividad.isNotEmpty)
                Text(
                  lectura.ultimaActividad,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),

              const SizedBox(height: 12),
            ],

            Text(
              "👥 ${lectura.totalLeyendo} leyendo · ✅ ${lectura.totalFinalizado} finalizaron",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        );
    }
  }
}
