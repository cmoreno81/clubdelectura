class ConversacionLibro {
  final String libro;
  final String tipo;
  final String estado;
  final int comentarios;
  final int likes;
  final String? ultimaActividad;

  const ConversacionLibro({
    required this.libro,
    required this.tipo,
    required this.estado,
    required this.comentarios,
    required this.likes,
    required this.ultimaActividad,
  });

  factory ConversacionLibro.fromJson(Map<String, dynamic> json) {
    return ConversacionLibro(
      libro: json["libro"] ?? "",
      tipo: json["tipo"] ?? "",
      estado: json["estado"] ?? "",
      comentarios: json["comentarios"] ?? 0,
      likes: json["likes"] ?? 0,
      ultimaActividad: json['ultimaActividad']?.toString(),
    );
  }
}
