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

  Notificacion copyWith({bool? leida}) => Notificacion(
    id: id,
    tipo: tipo,
    titulo: titulo,
    mensaje: mensaje,
    leida: leida ?? this.leida,
    fecha: fecha,
    clubId: clubId,
    bookId: bookId,
    extra: extra,
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

  /// Total de no leídas que devuelve el servidor (fuente de verdad global).
  final int noLeidas;

  // ── Contadores por destino, calculados sobre la lista recibida ──────────────
  // Si el servidor devuelve solo las más recientes, estos valores son
  // conservadores (pueden ser menores al total real), pero son suficientes
  // para el badge visual.

  /// Notificaciones que llevan a la pestaña Lecturas.
  int get noLeidasLecturas => notificaciones
      .where(
        (n) =>
            !n.leida &&
            (n.tipo == 'LECTURA_NUEVA' || n.tipo == 'COMENTARIO_LECTURA'),
      )
      .length;

  /// Notificaciones que llevan a la pestaña Clubvisión.
  int get noLeidasClubvision => notificaciones
      .where(
        (n) =>
            !n.leida &&
            (n.tipo == 'CLUBVISION_ABIERTA' ||
                n.tipo == 'CLUBVISION_RESULTADOS'),
      )
      .length;

  /// Notificaciones sociales que llevan al dashboard (El Club).
  int get noLeidasClub => notificaciones
      .where(
        (n) =>
            !n.leida &&
            (n.tipo == 'LIBRO_TERMINADO' ||
                n.tipo == 'LIBRO_EMPEZADO' ||
                n.tipo == 'LIBRO_NUEVO_BIBLIOTECA' ||
                n.tipo == 'NUEVA_MIEMBRO'),
      )
      .length;

  factory NotificacionesData.fromJson(Map<String, dynamic> json) =>
      NotificacionesData(
        notificaciones: (json['notificaciones'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(Notificacion.fromJson)
            .toList(growable: false),
        noLeidas: (json['noLeidas'] as num?)?.toInt() ?? 0,
      );
}
