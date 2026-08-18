class ClubvisionGanadorStats {
  const ClubvisionGanadorStats({
    required this.titulo,
    required this.bookId,
    required this.coverUrl,
    required this.edition,
    required this.puntos,
    required this.lectoras,
    required this.totalMiembros,
    required this.votantes,
    required this.totalComentarios,
    this.valoracionMedia,
  });

  final String titulo;
  final String bookId;
  final String coverUrl;
  final String edition;
  final int puntos;
  final int lectoras;
  final int totalMiembros;
  final int votantes;
  final int totalComentarios;
  final double? valoracionMedia;

  double get porcentajeLectoras =>
      totalMiembros > 0 ? (lectoras / totalMiembros).clamp(0.0, 1.0) : 0.0;

  factory ClubvisionGanadorStats.fromJson(Map<String, dynamic> json) =>
      ClubvisionGanadorStats(
        titulo: json['titulo']?.toString() ?? '',
        bookId: json['bookId']?.toString() ?? '',
        coverUrl: json['coverUrl']?.toString() ?? '',
        edition: json['edition']?.toString() ?? '',
        puntos: (json['puntos'] as num?)?.toInt() ?? 0,
        lectoras: (json['lectoras'] as num?)?.toInt() ?? 0,
        totalMiembros: (json['totalMiembros'] as num?)?.toInt() ?? 0,
        votantes: (json['votantes'] as num?)?.toInt() ?? 0,
        totalComentarios: (json['totalComentarios'] as num?)?.toInt() ?? 0,
        valoracionMedia: (json['valoracionMedia'] as num?)?.toDouble(),
      );
}

class ClubvisionEstadisticas {
  const ClubvisionEstadisticas({
    required this.totalEdiciones,
    required this.participacionMedia,
    required this.totalMiembros,
    required this.ganadores,
  });

  final int totalEdiciones;
  final int participacionMedia;
  final int totalMiembros;
  final List<ClubvisionGanadorStats> ganadores;

  /// Libro más leído (mayor porcentaje de lectoras)
  ClubvisionGanadorStats? get masLeido => ganadores.isEmpty
      ? null
      : ganadores.reduce((a, b) => a.lectoras >= b.lectoras ? a : b);

  /// Libro mejor valorado
  ClubvisionGanadorStats? get mejorValorado {
    final conValoracion =
        ganadores.where((g) => g.valoracionMedia != null).toList();
    if (conValoracion.isEmpty) return null;
    return conValoracion.reduce(
      (a, b) => a.valoracionMedia! >= b.valoracionMedia! ? a : b,
    );
  }

  /// Libro más comentado
  ClubvisionGanadorStats? get masComentado => ganadores.isEmpty
      ? null
      : ganadores.reduce(
          (a, b) => a.totalComentarios >= b.totalComentarios ? a : b,
        );

  factory ClubvisionEstadisticas.fromJson(Map<String, dynamic> json) =>
      ClubvisionEstadisticas(
        totalEdiciones: (json['totalEdiciones'] as num?)?.toInt() ?? 0,
        participacionMedia: (json['participacionMedia'] as num?)?.toInt() ?? 0,
        totalMiembros: (json['totalMiembros'] as num?)?.toInt() ?? 0,
        ganadores: (json['ganadores'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ClubvisionGanadorStats.fromJson)
            .toList(),
      );
}
