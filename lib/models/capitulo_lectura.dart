class CapituloLectura {
  final String nombre;
  final int comentarios;
  final int likes;
  final String ultimaActividad;

  const CapituloLectura({
    required this.nombre,
    required this.comentarios,
    required this.likes,
    required this.ultimaActividad,
  });

  factory CapituloLectura.fromJson(Map<String, dynamic> json) {
    return CapituloLectura(
      nombre: json["nombre"] ?? "",
      comentarios: json["comentarios"] ?? 0,
      likes: json["likes"] ?? 0,
      ultimaActividad: json["ultimaActividad"]?.toString() ?? "",
    );
  }
}
