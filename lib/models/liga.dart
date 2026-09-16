// Modelos de las Ligas de ClubReads (ranking individual por temporadas).

import 'package:flutter/material.dart';

/// De menor a mayor. Todo el mundo empieza en Bronce.
enum LigaDivision {
  bronce('🥉', Color(0xFFA9714B)),
  plata('🥈', Color(0xFF8E97A6)),
  oro('🥇', Color(0xFFD5A94E)),
  platino('💎', Color(0xFF5FA8B8)),
  diamante('👑', Color(0xFF7C5CBF));

  const LigaDivision(this.icono, this.color);
  final String icono;
  final Color color;

  String get etiqueta => switch (this) {
    LigaDivision.bronce => 'Bronce',
    LigaDivision.plata => 'Plata',
    LigaDivision.oro => 'Oro',
    LigaDivision.platino => 'Platino',
    LigaDivision.diamante => 'Diamante',
  };

  /// Explicación breve de qué es esta división, para leyendas dentro de la app.
  String get descripcion => switch (this) {
    LigaDivision.bronce => 'División inicial. Todo el mundo empieza aquí.',
    LigaDivision.plata => 'Se asciende desde Bronce quedando arriba de tabla.',
    LigaDivision.oro => 'División intermedia de la escalera.',
    LigaDivision.platino => 'Penúltimo escalón, para las más constantes.',
    LigaDivision.diamante =>
      'División más alta. No hay ascenso posible desde aquí.',
  };

  static LigaDivision fromJson(String? value) => switch (value) {
    'PLATA' => LigaDivision.plata,
    'ORO' => LigaDivision.oro,
    'PLATINO' => LigaDivision.platino,
    'DIAMANTE' => LigaDivision.diamante,
    _ => LigaDivision.bronce,
  };
}

class LigaTemporada {
  final int numero;
  final DateTime terminaEn;
  final int totalParticipantes;
  final LigaDivision division;

  const LigaTemporada({
    required this.numero,
    required this.terminaEn,
    required this.totalParticipantes,
    required this.division,
  });

  factory LigaTemporada.fromJson(Map<String, dynamic> json) => LigaTemporada(
    numero: (json['numero'] as num?)?.toInt() ?? 0,
    terminaEn:
        DateTime.tryParse(json['terminaEn']?.toString() ?? '')?.toLocal() ??
        DateTime.now(),
    totalParticipantes: (json['totalParticipantes'] as num?)?.toInt() ?? 0,
    division: LigaDivision.fromJson(json['division']?.toString()),
  );
}

/// Si sube, baja o se mantiene desde el último ciclo del cron (~cada 1-3 h).
/// Null = aún no hay dato de comparación (p. ej. recién unida).
enum LigaTendencia { sube, baja, igual;

  static LigaTendencia? fromJson(String? value) => switch (value) {
    'sube' => LigaTendencia.sube,
    'baja' => LigaTendencia.baja,
    'igual' => LigaTendencia.igual,
    _ => null,
  };
}

class LigaFila {
  final int puesto;
  final String userId;
  final String nombre;
  final String? avatarUrl;
  final int puntos;
  final bool esTu;
  final LigaTendencia? tendencia;
  final int? delta;
  final int? rachaHoy;

  const LigaFila({
    required this.puesto,
    required this.userId,
    required this.nombre,
    required this.avatarUrl,
    required this.puntos,
    required this.esTu,
    this.tendencia,
    this.delta,
    this.rachaHoy,
  });

  factory LigaFila.fromJson(Map<String, dynamic> json) => LigaFila(
    puesto: (json['puesto'] as num?)?.toInt() ?? 0,
    userId: json['userId']?.toString() ?? '',
    nombre: json['nombre']?.toString() ?? '',
    avatarUrl: (json['avatarUrl']?.toString().trim().isEmpty ?? true)
        ? null
        : json['avatarUrl'].toString(),
    puntos: (json['puntos'] as num?)?.toInt() ?? 0,
    esTu: json['esTu'] == true,
    tendencia: LigaTendencia.fromJson(json['tendencia']?.toString()),
    delta: (json['delta'] as num?)?.toInt(),
    rachaHoy: (json['rachaHoy'] as num?)?.toInt(),
  );
}

/// Etiqueta + emoji de cada tipo de evento de puntos, para la leyenda y el
/// desglose. Debe reflejar los `RankingEventType` del backend.
const Map<String, (String emoji, String etiqueta)> kLigaTiposPuntos = {
  'CHECKIN': ('✅', 'Check-in diario'),
  'STREAK_BONUS': ('🔥', 'Bonus por racha'),
  'PAGES': ('📄', 'Páginas leídas'),
  'BOOK_FINISHED': ('📕', 'Libros terminados'),
  'FIRST_BOOK_OF_MONTH': ('📆', 'Primer libro del mes'),
  'SAGA_COMPLETED': ('📚', 'Sagas completadas'),
  'REVIEW': ('✍️', 'Reseñas con texto'),
  'BOOK_OF_YEAR_PICK': ('👑', 'Libro del año elegido'),
  'QUIZ': ('🧠', 'Quizzes'),
  'WEEKLY_CHALLENGE': ('🎯', 'Reto semanal'),
};

class LigaDesgloseItem {
  final String tipo;
  final int puntos;
  final int eventos;

  const LigaDesgloseItem({
    required this.tipo,
    required this.puntos,
    required this.eventos,
  });

  factory LigaDesgloseItem.fromJson(Map<String, dynamic> json) =>
      LigaDesgloseItem(
        tipo: json['tipo']?.toString() ?? '',
        puntos: (json['puntos'] as num?)?.toInt() ?? 0,
        eventos: (json['eventos'] as num?)?.toInt() ?? 0,
      );

  String get emoji => kLigaTiposPuntos[tipo]?.$1 ?? '⭐';
  String get etiqueta => kLigaTiposPuntos[tipo]?.$2 ?? tipo;
}

class LigaDesglose {
  final bool ok;
  final String mensaje;
  final String nombre;
  final String? avatarUrl;
  final LigaDivision division;
  final int? puesto;
  final int puntos;
  final List<LigaDesgloseItem> desglose;

  const LigaDesglose({
    required this.ok,
    required this.mensaje,
    required this.nombre,
    required this.avatarUrl,
    required this.division,
    required this.puesto,
    required this.puntos,
    required this.desglose,
  });

  factory LigaDesglose.fromJson(Map<String, dynamic> json) => LigaDesglose(
    ok: json['ok'] == true,
    mensaje: json['mensaje']?.toString() ?? '',
    nombre: json['nombre']?.toString() ?? '',
    avatarUrl: (json['avatarUrl']?.toString().trim().isEmpty ?? true)
        ? null
        : json['avatarUrl'].toString(),
    division: LigaDivision.fromJson(json['division']?.toString()),
    puesto: (json['puesto'] as num?)?.toInt(),
    puntos: (json['puntos'] as num?)?.toInt() ?? 0,
    desglose: ((json['desglose'] as List?) ?? const [])
        .map(
          (e) => LigaDesgloseItem.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
  );
}

class LigaHistorico {
  final int temporadasJugadas;
  final int? mejorPuesto;
  final int? mejorPuntuacion;
  final int podios;
  final LigaDivision? mejorDivision;

  const LigaHistorico({
    required this.temporadasJugadas,
    required this.mejorPuesto,
    required this.mejorPuntuacion,
    required this.podios,
    required this.mejorDivision,
  });

  factory LigaHistorico.fromJson(Map<String, dynamic>? json) => LigaHistorico(
    temporadasJugadas: (json?['temporadasJugadas'] as num?)?.toInt() ?? 0,
    mejorPuesto: (json?['mejorPuesto'] as num?)?.toInt(),
    mejorPuntuacion: (json?['mejorPuntuacion'] as num?)?.toInt(),
    podios: (json?['podios'] as num?)?.toInt() ?? 0,
    mejorDivision: json?['mejorDivision'] == null
        ? null
        : LigaDivision.fromJson(json?['mejorDivision']?.toString()),
  );
}

class LigaObjetivo {
  final String nombre;
  final int puntos;
  final int diferencia;

  const LigaObjetivo({
    required this.nombre,
    required this.puntos,
    required this.diferencia,
  });

  factory LigaObjetivo.fromJson(Map<String, dynamic> json) => LigaObjetivo(
    nombre: json['nombre']?.toString() ?? '',
    puntos: (json['puntos'] as num?)?.toInt() ?? 0,
    diferencia: (json['diferencia'] as num?)?.toInt() ?? 0,
  );
}

class LigaRetoSemanal {
  final int objetivo;
  final int progreso;
  final int puntos;
  final bool completado;

  const LigaRetoSemanal({
    required this.objetivo,
    required this.progreso,
    required this.puntos,
    required this.completado,
  });

  factory LigaRetoSemanal.fromJson(Map<String, dynamic>? json) =>
      LigaRetoSemanal(
        objetivo: (json?['objetivo'] as num?)?.toInt() ?? 5,
        progreso: (json?['progreso'] as num?)?.toInt() ?? 0,
        puntos: (json?['puntos'] as num?)?.toInt() ?? 0,
        completado: json?['completado'] == true,
      );
}

class LigaEstado {
  final bool participando;
  final LigaTemporada temporada;
  final int miPuesto;
  final int misPuntos;
  final LigaObjetivo? siguienteObjetivo;
  final List<LigaFila> tabla;
  final LigaHistorico historico;
  final LigaRetoSemanal? retoSemanal;

  const LigaEstado({
    required this.participando,
    required this.temporada,
    required this.miPuesto,
    required this.misPuntos,
    required this.siguienteObjetivo,
    required this.tabla,
    required this.historico,
    required this.retoSemanal,
  });

  factory LigaEstado.fromJson(Map<String, dynamic> json) => LigaEstado(
    participando: json['participando'] == true,
    temporada: LigaTemporada.fromJson(
      (json['temporada'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    miPuesto: (json['miPuesto'] as num?)?.toInt() ?? 0,
    misPuntos: (json['misPuntos'] as num?)?.toInt() ?? 0,
    siguienteObjetivo: json['siguienteObjetivo'] == null
        ? null
        : LigaObjetivo.fromJson(
            Map<String, dynamic>.from(json['siguienteObjetivo'] as Map),
          ),
    tabla: ((json['tabla'] as List?) ?? const [])
        .map((e) => LigaFila.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    historico: LigaHistorico.fromJson(
      (json['historico'] as Map?)?.cast<String, dynamic>(),
    ),
    retoSemanal: json['retoSemanal'] == null
        ? null
        : LigaRetoSemanal.fromJson(
            Map<String, dynamic>.from(json['retoSemanal'] as Map),
          ),
  );
}
