import 'capitulo_lectura.dart';

/// Meta opcional de una lectura conjunta: hasta qué capítulo se lee y qué día
/// se comenta. [fecha] va en formato `yyyy-MM-dd`.
class MetaLectura {
  const MetaLectura({required this.capitulo, required this.fecha});

  final int capitulo;
  final String fecha;

  factory MetaLectura.fromJson(Map<String, dynamic> json) => MetaLectura(
    capitulo: (json['capitulo'] as num?)?.toInt() ?? 0,
    fecha: json['fecha']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {'capitulo': capitulo, 'fecha': fecha};

  DateTime? get dia => DateTime.tryParse(fecha);
}

class ConfiguracionLectura {
  final int capitulos;
  final bool prologo;
  final bool epilogo;
  final String coverUrl;
  final String bookId;

  final List<CapituloLectura> capitulosDisponibles;

  /// Metas de la lectura (vacía si el club no ha puesto ninguna).
  final List<MetaLectura> metas;

  ConfiguracionLectura({
    required this.capitulos,
    required this.prologo,
    required this.epilogo,
    required this.capitulosDisponibles,
    required this.coverUrl,
    required this.bookId,
    this.metas = const [],
  });

  /// Próxima meta (la de hoy cuenta) con el rango de capítulos que cubre, o
  /// `null` si no hay metas por delante.
  ({MetaLectura meta, int desde})? proximaMeta(DateTime hoy) {
    final ordenadas = [...metas]
      ..sort((a, b) => a.capitulo.compareTo(b.capitulo));
    final dia = DateTime(hoy.year, hoy.month, hoy.day);
    var anterior = 0;
    for (final meta in ordenadas) {
      final fecha = meta.dia;
      if (fecha != null && !fecha.isBefore(dia)) {
        return (meta: meta, desde: anterior + 1);
      }
      anterior = meta.capitulo;
    }
    return null;
  }

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
      metas: (json['metas'] as List? ?? [])
          .whereType<Map>()
          .map((e) => MetaLectura.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
