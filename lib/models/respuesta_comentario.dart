class RespuestaComentario {
  final String id;
  final String comentarioId;
  final String usuario;
  final String fecha;
  final String respuesta;
  final int likes;
  final bool miLike;
  final bool editado;
  final bool eliminado;
  final bool esMia;

  const RespuestaComentario({
    required this.id,
    required this.comentarioId,
    required this.usuario,
    required this.fecha,
    required this.respuesta,
    required this.likes,
    required this.miLike,
    required this.editado,
    required this.eliminado,
    required this.esMia,
  });

  factory RespuestaComentario.fromJson(Map<String, dynamic> json) {
    return RespuestaComentario(
      id: json["id"] ?? "",
      comentarioId: json["comentarioId"] ?? "",
      usuario: json["usuario"] ?? "",
      fecha: json["fecha"] ?? "",
      respuesta: json["respuesta"] ?? "",
      likes: json["likes"] ?? 0,
      miLike: json["miLike"] ?? false,
      editado: json["editado"] ?? false,
      eliminado: json["eliminado"] ?? false,
      esMia: json["esMia"] ?? false,
    );
  }
}
