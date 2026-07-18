import 'package:flutter/material.dart';

import 'respuesta_comentario.dart';
import 'reaccion_comentario.dart';

class ComentarioLectura {
  final String id;

  final String libro;
  final String capitulo;

  final String usuario;
  final String avatarUrl;
  final String fecha;

  final String comentario;

  final int likes;

  final bool miLike;
  final Map<ReaccionComentario, int> reacciones;
  final ReaccionComentario? miReaccion;

  final bool editado;
  final bool eliminado;

  final bool esMio;

  final List<RespuestaComentario> respuestas;

  const ComentarioLectura({
    required this.id,
    required this.libro,
    required this.capitulo,
    required this.usuario,
    required this.avatarUrl,
    required this.fecha,
    required this.comentario,
    required this.likes,
    required this.miLike,
    required this.reacciones,
    required this.miReaccion,
    required this.editado,
    required this.eliminado,
    required this.esMio,
    required this.respuestas,
  });

  factory ComentarioLectura.fromJson(Map<String, dynamic> json) {
    debugPrint('Comentario JSON: $json');

    return ComentarioLectura(
      id: json["id"]?.toString() ?? "",
      libro: json["libro"]?.toString() ?? "",
      capitulo: json["capitulo"]?.toString() ?? "",
      usuario: json["usuario"]?.toString() ?? "",
      avatarUrl:
          json["avatarUrl"]?.toString() ??
          json["fotoUrl"]?.toString() ??
          json["photoUrl"]?.toString() ??
          "",
      fecha: json["fecha"]?.toString() ?? "",
      comentario: json["comentario"]?.toString() ?? "",
      likes: json["likes"] as int? ?? 0,
      miLike: json["miLike"] as bool? ?? false,
      reacciones: _parseReacciones(json),
      miReaccion: ReaccionComentarioDatos.fromApi(
        json["miReaccion"]?.toString() ??
            ((json["miLike"] as bool? ?? false) ? 'LIKE' : null),
      ),
      editado: json["editado"] as bool? ?? false,
      eliminado: json["eliminado"] as bool? ?? false,
      esMio: json["esMio"] as bool? ?? false,
      respuestas: (json["respuestas"] as List? ?? [])
          .map(
            (e) => RespuestaComentario.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  static Map<ReaccionComentario, int> _parseReacciones(
    Map<String, dynamic> json,
  ) {
    final raw = json['reacciones'];
    final values = raw is Map ? raw : const <String, dynamic>{};
    return {
      for (final reaccion in ReaccionComentario.values)
        reaccion:
            (values[reaccion.apiValue] as num?)?.toInt() ??
            (reaccion == ReaccionComentario.meGusta
                ? (json['likes'] as num?)?.toInt() ?? 0
                : 0),
    };
  }
}
