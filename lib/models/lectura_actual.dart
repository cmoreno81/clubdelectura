class LecturaFinalizada {
  final String usuario;
  final String valoracion;

  const LecturaFinalizada({required this.usuario, required this.valoracion});

  factory LecturaFinalizada.fromJson(Map<String, dynamic> json) {
    return LecturaFinalizada(
      usuario: json['usuario'] ?? '',
      valoracion: json['valoracion'] ?? '',
    );
  }
}

class LecturaActual {
  final String titulo;

  final List<String> leyendo;

  final List<LecturaFinalizada> finalizado;

  final int totalLeyendo;

  final int totalFinalizado;

  const LecturaActual({
    required this.titulo,
    required this.leyendo,
    required this.finalizado,
    required this.totalLeyendo,
    required this.totalFinalizado,
  });

  factory LecturaActual.fromJson(Map<String, dynamic> json) {
    return LecturaActual(
      titulo: json['titulo'] ?? '',

      leyendo: List<String>.from(json['leyendo'] ?? []),

      finalizado: (json['finalizado'] as List<dynamic>? ?? [])
          .map((e) => LecturaFinalizada.fromJson(e))
          .toList(),

      totalLeyendo: json['totalLeyendo'] ?? 0,

      totalFinalizado: json['totalFinalizado'] ?? 0,
    );
  }
}
