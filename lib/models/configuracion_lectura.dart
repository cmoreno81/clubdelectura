import 'capitulo_lectura.dart';

class ConfiguracionLectura {
  final int capitulos;
  final bool prologo;
  final bool epilogo;
  final String coverUrl;
  final String bookId;

  final List<CapituloLectura> capitulosDisponibles;

  ConfiguracionLectura({
    required this.capitulos,
    required this.prologo,
    required this.epilogo,
    required this.capitulosDisponibles,
    required this.coverUrl,
    required this.bookId,
  });

  factory ConfiguracionLectura.fromJson(Map<String, dynamic> json) {
    return ConfiguracionLectura(
      capitulos: json["capitulos"] ?? 0,
      prologo: json["prologo"] ?? false,
      epilogo: json["epilogo"] ?? false,
      coverUrl: json['coverUrl']?.toString() ?? '',
      bookId: json['bookId']?.toString() ?? '',
      capitulosDisponibles: (json["capitulosDisponibles"] as List? ?? [])
          .map((e) => CapituloLectura.fromJson(e))
          .toList(),
    );
  }
}
