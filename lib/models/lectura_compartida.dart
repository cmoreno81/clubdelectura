import 'package:club_lectura_app/models/lector_finalizado.dart';

class LecturaCompartida {
  final String libro;
  final int capitulos;
  final bool prologo;
  final bool epilogo;

  final List<String> leyendo;
  final List<LectorFinalizado> finalizados;
  final List<String> capitulosDisponibles;

  LecturaCompartida({
    required this.libro,
    required this.capitulos,
    required this.prologo,
    required this.epilogo,
    required this.leyendo,
    required this.finalizados,
    required this.capitulosDisponibles,
  });

  factory LecturaCompartida.fromJson(Map<String, dynamic> json) {
    return LecturaCompartida(
      libro: json["libro"] ?? "",
      capitulos: json["capitulos"] ?? 0,
      prologo: json["prologo"] ?? false,
      epilogo: json["epilogo"] ?? false,
      leyendo: List<String>.from(json["leyendo"] ?? []),
      finalizados: (json["finalizados"] as List? ?? [])
          .map((e) => LectorFinalizado.fromJson(e))
          .toList(),
      capitulosDisponibles: List<String>.from(
        json["capitulosDisponibles"] ?? [],
      ),
    );
  }
}
