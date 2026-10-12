class CapituloLectura {
  final String nombre;
  final int comentarios;
  final int likes;
  final String? ultimaActividad;

  /// En lecturas con metas, los capítulos por delante de la meta en curso
  /// están cerrados hasta [desbloqueaEl] (`yyyy-MM-dd`).
  final bool bloqueado;
  final String? desbloqueaEl;

  final int nuevosComentarios;
  final bool tieneNovedades;
  final int respuestas;
  final int nuevasRespuestas;
  final int nuevosTotal;

  const CapituloLectura({
    required this.nombre,
    required this.comentarios,
    required this.likes,
    required this.ultimaActividad,
    required this.nuevosComentarios,
    required this.tieneNovedades,
    required this.respuestas,
    required this.nuevasRespuestas,
    required this.nuevosTotal,
    this.bloqueado = false,
    this.desbloqueaEl,
  });

  factory CapituloLectura.fromJson(Map<String, dynamic> json) {
    final nuevosComentarios = (json['nuevosComentarios'] as num?)?.toInt() ?? 0;

    final nuevasRespuestas = (json['nuevasRespuestas'] as num?)?.toInt() ?? 0;

    final nuevosTotal =
        (json['nuevosTotal'] as num?)?.toInt() ??
        nuevosComentarios + nuevasRespuestas;

    return CapituloLectura(
      nombre: json['nombre']?.toString() ?? '',
      comentarios: (json['comentarios'] as num?)?.toInt() ?? 0,
      respuestas: (json['respuestas'] as num?)?.toInt() ?? 0,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      ultimaActividad: json['ultimaActividad']?.toString(),
      nuevosComentarios: nuevosComentarios,
      nuevasRespuestas: nuevasRespuestas,
      nuevosTotal: nuevosTotal,
      tieneNovedades: json['tieneNovedades'] as bool? ?? nuevosTotal > 0,
      bloqueado: json['bloqueado'] == true,
      desbloqueaEl: json['desbloqueaEl']?.toString(),
    );
  }
}
