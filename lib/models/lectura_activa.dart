class LecturaActiva {
  final String libro;
  final String coverUrl;
  final int lectoras;
  final bool configurada;
  final int comentarios;
  final String? ultimaActividad;
  final String tipo;
  final String estado;

  const LecturaActiva({
    required this.libro,
    required this.coverUrl,
    required this.lectoras,
    required this.configurada,
    required this.comentarios,
    required this.ultimaActividad,
    required this.tipo,
    required this.estado,
  });

  factory LecturaActiva.fromJson(Map<String, dynamic> json) {
    return LecturaActiva(
      libro: json['libro']?.toString() ?? '',
      coverUrl: json['coverUrl']?.toString() ?? '',
      lectoras: _toInt(json['lectoras']),
      configurada: json['configurada'] == true,
      comentarios: _toInt(json['comentarios']),
      ultimaActividad: json['ultimaActividad']?.toString(),
      tipo: json['tipo']?.toString().toUpperCase() ?? 'LIBRE',
      estado: json['estado']?.toString().toUpperCase() ?? 'ACTIVA',
    );
  }

  bool get esOficial => tipo == 'OFICIAL';

  bool get estaActiva => estado == 'ACTIVA';

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
