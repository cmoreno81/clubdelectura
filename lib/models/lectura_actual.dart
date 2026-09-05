class LecturaFinalizada {
  final String usuario;
  final String valoracion;

  const LecturaFinalizada({required this.usuario, required this.valoracion});

  factory LecturaFinalizada.fromJson(Map<String, dynamic> json) {
    return LecturaFinalizada(
      usuario: json['usuario']?.toString() ?? '',
      valoracion: json['valoracion']?.toString() ?? '',
    );
  }
}

class LecturaActual {
  /// true solo si hay una lectura oficial real (ganadora de Clubvisión o
  /// lectura activa de respaldo). `titulo` no sirve para esto: cuando no
  /// hay lectura real, el backend rellena `titulo` con un mensaje genérico
  /// ("Aún no hay libros con suficiente interés...") en vez de dejarlo vacío.
  final bool ok;
  final String titulo;

  final List<String> leyendo;

  final List<LecturaFinalizada> finalizado;

  final int totalLeyendo;

  final int totalFinalizado;

  final int comentarios;
  final int likes;
  final String? ultimaActividad;
  final String coverUrl;

  const LecturaActual({
    required this.ok,
    required this.titulo,
    required this.leyendo,
    required this.finalizado,
    required this.totalLeyendo,
    required this.totalFinalizado,
    required this.comentarios,
    required this.likes,
    required this.ultimaActividad,
    required this.coverUrl,
  });

  factory LecturaActual.fromJson(Map<String, dynamic> json) {
    return LecturaActual(
      ok: json['ok'] == true,
      titulo: json['titulo'] ?? '',

      leyendo: List<String>.from(json['leyendo'] ?? []),

      finalizado: (json['finalizado'] as List? ?? [])
          .map((e) => LecturaFinalizada.fromJson(e as Map<String, dynamic>))
          .toList(),

      totalLeyendo: json['totalLeyendo'] ?? 0,

      totalFinalizado: json['totalFinalizado'] ?? 0,
      comentarios: (json["comentarios"] as num?)?.toInt() ?? 0,
      likes: (json["likes"] as num?)?.toInt() ?? 0,
      ultimaActividad: json['ultimaActividad']?.toString(),
      coverUrl: json['coverUrl']?.toString() ?? '',
    );
  }
}
