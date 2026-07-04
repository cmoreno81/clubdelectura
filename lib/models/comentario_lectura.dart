class ComentarioLectura {
  final String libro;
  final String capitulo;
  final String usuario;
  final String fecha;
  final String comentario;
  final int likes;
  final bool editado;
  final bool eliminado;

  ComentarioLectura({
    required this.libro,
    required this.capitulo,
    required this.usuario,
    required this.fecha,
    required this.comentario,
    required this.likes,
    required this.editado,
    required this.eliminado,
  });

  factory ComentarioLectura.fromJson(Map<String, dynamic> json) {
    return ComentarioLectura(
      libro: json["libro"] ?? "",
      capitulo: json["capitulo"] ?? "",
      usuario: json["usuario"] ?? "",
      fecha: json["fecha"] ?? "",
      comentario: json["comentario"] ?? "",
      likes: json["likes"] ?? 0,
      editado: json["editado"] ?? false,
      eliminado: json["eliminado"] ?? false,
    );
  }
}
