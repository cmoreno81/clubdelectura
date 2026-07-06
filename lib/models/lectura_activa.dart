class LecturaActiva {
  final String libro;
  final int lectoras;
  final bool configurada;
  final int comentarios;
  final String ultimaActividad;

  const LecturaActiva({
    required this.libro,
    required this.lectoras,
    required this.configurada,
    required this.comentarios,
    required this.ultimaActividad,
  });

  factory LecturaActiva.fromJson(Map<String, dynamic> json) {
    return LecturaActiva(
      libro: json["libro"] ?? "",
      lectoras: json["lectoras"] ?? 0,
      configurada: json["configurada"] ?? false,
      comentarios: json["comentarios"] ?? 0,
      ultimaActividad: json["ultimaActividad"] ?? "",
    );
  }
}
