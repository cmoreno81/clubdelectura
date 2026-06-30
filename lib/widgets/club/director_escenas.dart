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
        return Column(
          children: [
            const SizedBox(height: 10),
            Text(
              dashboard.clubvision.mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
          ],
        );
    }
  }
}
