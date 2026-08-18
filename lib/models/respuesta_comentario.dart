import 'reaccion_comentario.dart';

class RespuestaComentario {
  final String id;
  final String comentarioId;
  final String usuario;
  final String avatarUrl;
  final String fecha;
  final String respuesta;
  final int likes;
  final bool miLike;
  final bool editado;
  final bool eliminado;
  final bool esMia;

  /// `true` si esta respuesta se publicó después de la última visita
  /// del usuario actual al capítulo.
  final bool esNueva;

  final Map<ReaccionComentario, int> reacciones;
  final ReaccionComentario? miReaccion;

  const RespuestaComentario({
    required this.id,
    required this.comentarioId,
    required this.usuario,
    required this.avatarUrl,
    required this.fecha,
    required this.respuesta,
    required this.likes,
    required this.miLike,
    required this.editado,
    required this.eliminado,
    required this.esMia,
    this.esNueva = false,
    this.reacciones = const {},
    this.miReaccion,
  });

  factory RespuestaComentario.fromJson(Map<String, dynamic> json) {
    return RespuestaComentario(
      id: json["id"]?.toString() ?? "",
      comentarioId: json["comentarioId"]?.toString() ?? "",
      usuario: json["usuario"]?.toString() ?? "",
      avatarUrl:
          json["avatarUrl"]?.toString() ??
          json["fotoUrl"]?.toString() ??
          json["photoUrl"]?.toString() ??
          "",
      fecha: json["fecha"]?.toString() ?? "",
      respuesta: json["respuesta"]?.toString() ?? "",
      likes: json["likes"] as int? ?? 0,
      miLike: json["miLike"] as bool? ?? false,
      editado: json["editado"] as bool? ?? false,
      eliminado: json["eliminado"] as bool? ?? false,
      esMia: json["esMia"] as bool? ?? false,
      esNueva: json["esNueva"] as bool? ?? false,
      reacciones: {
        for (final tipo in ReaccionComentario.values)
          tipo:
              ((json['reacciones'] as Map?)?[tipo.apiValue] as num?)?.toInt() ??
              0,
      },
      miReaccion: ReaccionComentarioDatos.fromApi(
        json['miReaccion']?.toString(),
      ),
    );
  }
}
