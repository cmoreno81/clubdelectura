/// Estadísticas personales para "Mis estadísticas": ritmo de lectura,
/// géneros del año en curso y los superlativos del año (libro más largo,
/// lectura más rápida). Ver `getEstadisticasPersonales` en el backend
/// (checkin.service.ts).
class RitmoLectura {
  const RitmoLectura({
    required this.paginasPorDiaMes,
    required this.variacionPct,
    required this.serie,
  });

  final double paginasPorDiaMes;
  /// null si no hay datos del mes anterior con los que comparar.
  final int? variacionPct;
  /// 12 cubos semanales de páginas leídas, para el sparkline.
  final List<int> serie;

  factory RitmoLectura.fromJson(Map<String, dynamic> json) => RitmoLectura(
    paginasPorDiaMes: (json['paginasPorDiaMes'] as num?)?.toDouble() ?? 0,
    variacionPct: (json['variacionPct'] as num?)?.toInt(),
    serie: ((json['serie'] as List?) ?? const [])
        .map((e) => (e as num).toInt())
        .toList(),
  );
}

class GeneroLectura {
  const GeneroLectura({required this.nombre, required this.porcentaje});
  final String nombre;
  final int porcentaje;

  factory GeneroLectura.fromJson(Map<String, dynamic> json) => GeneroLectura(
    nombre: json['nombre']?.toString() ?? '',
    porcentaje: (json['porcentaje'] as num?)?.toInt() ?? 0,
  );
}

class LibroMasLargo {
  const LibroMasLargo({required this.titulo, this.paginas, this.coverUrl});
  final String titulo;
  final int? paginas;
  final String? coverUrl;

  static LibroMasLargo? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return LibroMasLargo(
      titulo: json['titulo']?.toString() ?? '',
      paginas: (json['paginas'] as num?)?.toInt(),
      coverUrl: json['coverUrl']?.toString(),
    );
  }
}

class LecturaMasRapida {
  const LecturaMasRapida({required this.titulo, required this.dias, this.coverUrl});
  final String titulo;
  final int dias;
  final String? coverUrl;

  static LecturaMasRapida? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return LecturaMasRapida(
      titulo: json['titulo']?.toString() ?? '',
      dias: (json['dias'] as num?)?.toInt() ?? 0,
      coverUrl: json['coverUrl']?.toString(),
    );
  }
}

class EstadisticasPersonales {
  const EstadisticasPersonales({
    required this.ritmo,
    required this.generos,
    this.libroMasLargo,
    this.lecturaMasRapida,
  });

  final RitmoLectura ritmo;
  final List<GeneroLectura> generos;
  final LibroMasLargo? libroMasLargo;
  final LecturaMasRapida? lecturaMasRapida;

  factory EstadisticasPersonales.fromJson(Map<String, dynamic> json) =>
      EstadisticasPersonales(
        ritmo: RitmoLectura.fromJson(
          Map<String, dynamic>.from(json['ritmo'] as Map? ?? const {}),
        ),
        generos: ((json['generos'] as List?) ?? const [])
            .map((e) => GeneroLectura.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        libroMasLargo: LibroMasLargo.fromJson(
          (json['libroMasLargo'] as Map?)?.cast<String, dynamic>(),
        ),
        lecturaMasRapida: LecturaMasRapida.fromJson(
          (json['lecturaMasRapida'] as Map?)?.cast<String, dynamic>(),
        ),
      );
}
