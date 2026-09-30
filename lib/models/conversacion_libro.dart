class ConversacionLibro {
  final String libro;
  final String tipo;
  final String estado;
  final int comentarios;
  final int likes;
  final String? ultimaActividad;
  final String clubId;
  final String clubNombre;

  const ConversacionLibro({
    required this.libro,
    required this.tipo,
    required this.estado,
    required this.comentarios,
    required this.likes,
    required this.ultimaActividad,
    required this.clubId,
    required this.clubNombre,
  });

  factory ConversacionLibro.fromJson(Map<String, dynamic> json) {
    return ConversacionLibro(
      libro: json["libro"] ?? "",
      tipo: json["tipo"] ?? "",
      estado: json["estado"] ?? "",
      comentarios: json["comentarios"] ?? 0,
      likes: json["likes"] ?? 0,
      ultimaActividad: json['ultimaActividad']?.toString(),
      clubId: json['clubId']?.toString() ?? '',
      clubNombre: json['clubNombre']?.toString() ?? '',
    );
  }
}
