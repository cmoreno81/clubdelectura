import 'package:club_lectura_app/models/capitulo_lectura.dart';
import 'package:club_lectura_app/models/lector_finalizado.dart';

class LecturaCompartida {
  final bool configurada;

  final String libro;
  final int capitulos;
  final bool prologo;
  final bool epilogo;

  final List<String> leyendo;
  final List<LectorFinalizado> finalizados;
  final List<CapituloLectura> capitulosDisponibles;

  const LecturaCompartida({
    required this.configurada,
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
      configurada: json["configurada"] ?? true,

      libro: json["libro"] ?? "",

      capitulos: json["capitulos"] ?? 0,

      prologo: json["prologo"] ?? false,

      epilogo: json["epilogo"] ?? false,

      leyendo: List<String>.from(json["leyendo"] ?? []),

      finalizados: (json["finalizados"] as List? ?? [])
          .map((e) => LectorFinalizado.fromJson(e))
          .toList(),

      capitulosDisponibles: (json["capitulosDisponibles"] as List? ?? [])
          .map((e) => CapituloLectura.fromJson(e))
          .toList(),
    );
  }
}
