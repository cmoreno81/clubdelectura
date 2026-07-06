import 'respuesta_comentario.dart';

class ComentarioLectura {
  final String id;

  final String libro;
  final String capitulo;

  final String usuario;
  final String fecha;

  final String comentario;

  final int likes;

  final bool miLike;

  final bool editado;
  final bool eliminado;

  final bool esMio;

  final List<RespuestaComentario> respuestas;

  const ComentarioLectura({
    required this.id,
    required this.libro,
    required this.capitulo,
    required this.usuario,
    required this.fecha,
    required this.comentario,
    required this.likes,
    required this.miLike,
    required this.editado,
    required this.eliminado,
    required this.esMio,
    required this.respuestas,
  });

  factory ComentarioLectura.fromJson(Map<String, dynamic> json) {
    return ComentarioLectura(
      id: json["id"] ?? "",

      libro: json["libro"] ?? "",
      capitulo: json["capitulo"] ?? "",

      usuario: json["usuario"] ?? "",
      fecha: json["fecha"] ?? "",

      comentario: json["comentario"] ?? "",

      likes: json["likes"] ?? 0,

      miLike: json["miLike"] ?? false,

      editado: json["editado"] ?? false,

      eliminado: json["eliminado"] ?? false,

      esMio: json["esMio"] ?? false,

      respuestas: (json["respuestas"] as List? ?? [])
          .map((e) => RespuestaComentario.fromJson(e))
          .toList(),
    );
  }
}
