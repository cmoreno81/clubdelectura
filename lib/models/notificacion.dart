class Notificacion {
  const Notificacion({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.leida,
    required this.fecha,
    this.clubId,
    this.bookId,
    this.extra,
  });

  final String id;
  final String tipo;
  final String titulo;
  final String mensaje;
  final bool leida;
  final String fecha;
  final String? clubId;
  final String? bookId;
  final Map<String, dynamic>? extra;

  factory Notificacion.fromJson(Map<String, dynamic> json) => Notificacion(
    id: json['id']?.toString() ?? '',
    tipo: json['tipo']?.toString() ?? '',
    titulo: json['titulo']?.toString() ?? '',
    mensaje: json['mensaje']?.toString() ?? '',
    leida: json['leida'] == true,
    fecha: json['fecha']?.toString() ?? '',
    clubId: json['clubId']?.toString(),
    bookId: json['bookId']?.toString(),
    extra: json['extra'] as Map<String, dynamic>?,
  );

  /// Emoji representativo según el tipo
  String get emoji => switch (tipo) {
    'CLUBVISION_ABIERTA' => '🗳️',
    'CLUBVISION_RESULTADOS' => '🏆',
    'LECTURA_NUEVA' => '📖',
    'COMENTARIO_LECTURA' => '💬',
    'LIBRO_TERMINADO' => '✅',
    'LIBRO_EMPEZADO' => '📖',
    'LIBRO_NUEVO_BIBLIOTECA' => '✨',
    'NUEVA_MIEMBRO' => '👋',
    _ => '🔔',
  };
}

class NotificacionesData {
  const NotificacionesData({
    required this.notificaciones,
    required this.noLeidas,
  });

  final List<Notificacion> notificaciones;
  final int noLeidas;

  factory NotificacionesData.fromJson(Map<String, dynamic> json) =>
      NotificacionesData(
        notificaciones: (json['notificaciones'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(Notificacion.fromJson)
            .toList(growable: false),
        noLeidas: (json['noLeidas'] as num?)?.toInt() ?? 0,
      );
}
