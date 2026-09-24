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

/// Medallas de temporada — trofeos acumulables tipo videojuego, ganados al
/// cerrar una temporada (ver SeasonMedal/MedalTier en el backend).
enum LigaMedallaTier {
  podioOro('🏆', Color(0xFFD5A94E)),
  podioPlata('🎖️', Color(0xFF9AA4B2)),
  podioBronce('🏅', Color(0xFFA9714B)),
  ascenso('🚀', Color(0xFF5FA8B8)),
  diamante('💎', Color(0xFF7C5CBF)),
  constancia('⭐', Color(0xFFD97757));

  const LigaMedallaTier(this.icono, this.color);
  final String icono;
  final Color color;

  String get etiqueta => switch (this) {
    LigaMedallaTier.podioOro => 'Oro de temporada',
    LigaMedallaTier.podioPlata => 'Plata de temporada',
    LigaMedallaTier.podioBronce => 'Bronce de temporada',
    LigaMedallaTier.ascenso => 'Ascenso de división',
    LigaMedallaTier.diamante => 'Alcanzó Diamante',
    LigaMedallaTier.constancia => 'Constancia',
  };

  /// Cómo se consigue, para la leyenda.
  String get descripcion => switch (this) {
    LigaMedallaTier.podioOro => 'Quedar 1ª de tu división al cerrar una temporada.',
    LigaMedallaTier.podioPlata => 'Quedar 2ª de tu división al cerrar una temporada.',
    LigaMedallaTier.podioBronce => 'Quedar 3ª de tu división al cerrar una temporada.',
    LigaMedallaTier.ascenso => 'Subir de división al cerrar una temporada.',
    LigaMedallaTier.diamante => 'Llegar a la división Diamante por primera vez.',
    LigaMedallaTier.constancia =>
      'Jugar temporadas seguidas sin parar (3, 5, 10, 20, 30...).',
  };

  static LigaMedallaTier? fromJson(String? value) => switch (value) {
    'PODIO_ORO' => LigaMedallaTier.podioOro,
    'PODIO_PLATA' => LigaMedallaTier.podioPlata,
    'PODIO_BRONCE' => LigaMedallaTier.podioBronce,
    'ASCENSO' => LigaMedallaTier.ascenso,
    'DIAMANTE' => LigaMedallaTier.diamante,
    'CONSTANCIA' => LigaMedallaTier.constancia,
    _ => null,
  };
}

/// La medalla más reciente de una participante — lo justo para el icono
/// junto a su nombre en la clasificación.
class LigaMedallaReciente {
  final LigaMedallaTier tier;
  final int seasonNumber;

  const LigaMedallaReciente({required this.tier, required this.seasonNumber});

  static LigaMedallaReciente? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final tier = LigaMedallaTier.fromJson(json['tier']?.toString());
    if (tier == null) return null;
    return LigaMedallaReciente(
      tier: tier,
      seasonNumber: (json['seasonNumber'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Una medalla del medallero completo de una participante (perfil).
class LigaMedalla {
  final LigaMedallaTier tier;
  final int seasonNumber;
  final LigaDivision division;
  final int? rank;
  final int? streak;
  final DateTime awardedAt;

  const LigaMedalla({
    required this.tier,
    required this.seasonNumber,
    required this.division,
    required this.rank,
    required this.streak,
    required this.awardedAt,
  });

  static LigaMedalla? fromJson(Map<String, dynamic> json) {
    final tier = LigaMedallaTier.fromJson(json['tier']?.toString());
    if (tier == null) return null;
    return LigaMedalla(
      tier: tier,
      seasonNumber: (json['seasonNumber'] as num?)?.toInt() ?? 0,
      division: LigaDivision.fromJson(json['division']?.toString()),
      rank: (json['rank'] as num?)?.toInt(),
      streak: (json['streak'] as num?)?.toInt(),
      awardedAt:
          DateTime.tryParse(json['awardedAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}

/// Medallero completo de una participante (respuesta de `ligaMedallas`):
/// todas sus medallas, más un recuento por tipo para el resumen del perfil.
class LigaMedallero {
  final List<LigaMedalla> medallas;
  final Map<LigaMedallaTier, int> resumen;

  const LigaMedallero({required this.medallas, required this.resumen});

  static LigaMedallero? fromJson(Map<String, dynamic> json) {
    if (json['ok'] != true) return null;
    final medallas = ((json['medallas'] as List?) ?? const [])
        .map((e) => LigaMedalla.fromJson(Map<String, dynamic>.from(e as Map)))
        .whereType<LigaMedalla>()
        .toList();
    final resumenJson =
        (json['resumen'] as Map?)?.cast<String, dynamic>() ?? const {};
    final resumen = <LigaMedallaTier, int>{};
    for (final entry in resumenJson.entries) {
      final tier = LigaMedallaTier.fromJson(entry.key);
      if (tier != null) resumen[tier] = (entry.value as num?)?.toInt() ?? 0;
    }
    return LigaMedallero(medallas: medallas, resumen: resumen);
  }
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
  final LigaMedallaReciente? medallaReciente;

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
    this.medallaReciente,
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
    medallaReciente: LigaMedallaReciente.fromJson(
      (json['medallaReciente'] as Map?)?.cast<String, dynamic>(),
    ),
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
  'CONSTANCIA_TEMPORADA': ('🌱', 'Constancia entre temporadas'),
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

// ─────────────────────────────────────────────────────────────────────────────
// Histórico de temporadas cerradas (`ligaHistorial` / `ligaTemporadaCerrada`)
// ─────────────────────────────────────────────────────────────────────────────

/// Una medalla ganada en una temporada del histórico — versión reducida de
/// [LigaMedalla] (sin `seasonNumber`/`awardedAt`, ya implícitos en el
/// contexto de la temporada que la contiene).
class LigaHistorialMedalla {
  final LigaMedallaTier tier;
  final LigaDivision division;

  const LigaHistorialMedalla({required this.tier, required this.division});

  static LigaHistorialMedalla? fromJson(Map<String, dynamic> json) {
    final tier = LigaMedallaTier.fromJson(json['tier']?.toString());
    if (tier == null) return null;
    return LigaHistorialMedalla(
      tier: tier,
      division: LigaDivision.fromJson(json['division']?.toString()),
    );
  }
}

/// Una temporada cerrada en la que la usuaria participó, para la lista del
/// histórico (`ligaHistorial`).
class LigaHistorialTemporada {
  final int temporada;
  final LigaDivision division;
  final int puesto;
  final int puntos;
  final int totalParticipantes;
  final DateTime inicio;
  final DateTime fin;
  final List<LigaHistorialMedalla> medallas;

  const LigaHistorialTemporada({
    required this.temporada,
    required this.division,
    required this.puesto,
    required this.puntos,
    required this.totalParticipantes,
    required this.inicio,
    required this.fin,
    required this.medallas,
  });

  factory LigaHistorialTemporada.fromJson(Map<String, dynamic> json) =>
      LigaHistorialTemporada(
        temporada: (json['temporada'] as num?)?.toInt() ?? 0,
        division: LigaDivision.fromJson(json['division']?.toString()),
        puesto: (json['puesto'] as num?)?.toInt() ?? 0,
        puntos: (json['puntos'] as num?)?.toInt() ?? 0,
        totalParticipantes: (json['totalParticipantes'] as num?)?.toInt() ?? 0,
        inicio: DateTime.tryParse(json['inicio']?.toString() ?? '') ??
            DateTime.now(),
        fin: DateTime.tryParse(json['fin']?.toString() ?? '') ??
            DateTime.now(),
        medallas: ((json['medallas'] as List?) ?? const [])
            .map(
              (e) => LigaHistorialMedalla.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .whereType<LigaHistorialMedalla>()
            .toList(),
      );
}

/// Respuesta de `ligaHistorial`: todas las temporadas cerradas de la
/// usuaria, más reciente primero.
class LigaHistorial {
  final List<LigaHistorialTemporada> temporadas;

  const LigaHistorial({required this.temporadas});

  factory LigaHistorial.fromJson(Map<String, dynamic> json) => LigaHistorial(
    temporadas: ((json['temporadas'] as List?) ?? const [])
        .map(
          (e) => LigaHistorialTemporada.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList(),
  );
}

/// Cabecera de una temporada cerrada (`ligaTemporadaCerrada`).
class LigaTemporadaCerradaInfo {
  final int numero;
  final LigaDivision division;
  final DateTime inicio;
  final DateTime fin;
  final int totalParticipantes;

  const LigaTemporadaCerradaInfo({
    required this.numero,
    required this.division,
    required this.inicio,
    required this.fin,
    required this.totalParticipantes,
  });

  factory LigaTemporadaCerradaInfo.fromJson(Map<String, dynamic> json) =>
      LigaTemporadaCerradaInfo(
        numero: (json['numero'] as num?)?.toInt() ?? 0,
        division: LigaDivision.fromJson(json['division']?.toString()),
        inicio: DateTime.tryParse(json['inicio']?.toString() ?? '') ??
            DateTime.now(),
        fin: DateTime.tryParse(json['fin']?.toString() ?? '') ??
            DateTime.now(),
        totalParticipantes: (json['totalParticipantes'] as num?)?.toInt() ?? 0,
      );
}

/// Una medalla ganada al cerrar esta temporada concreta, con su puesto y/o
/// racha (`ligaTemporadaCerrada`).
class LigaMedallaCerrada {
  final LigaMedallaTier tier;
  final LigaDivision division;
  final int? rank;
  final int? streak;

  const LigaMedallaCerrada({
    required this.tier,
    required this.division,
    required this.rank,
    required this.streak,
  });

  static LigaMedallaCerrada? fromJson(Map<String, dynamic> json) {
    final tier = LigaMedallaTier.fromJson(json['tier']?.toString());
    if (tier == null) return null;
    return LigaMedallaCerrada(
      tier: tier,
      division: LigaDivision.fromJson(json['division']?.toString()),
      rank: (json['rank'] as num?)?.toInt(),
      streak: (json['streak'] as num?)?.toInt(),
    );
  }
}

/// Respuesta de `ligaTemporadaCerrada`: detalle completo de una temporada ya
/// cerrada (tabla final, tu puesto y las medallas que ganaste). `ok: false`
/// cuando la temporada no existe, no ha cerrado o no la jugaste — en ese
/// caso solo [mensaje] tiene contenido útil.
class LigaTemporadaCerrada {
  final bool ok;
  final String mensaje;
  final LigaTemporadaCerradaInfo? temporada;
  final int? miPuesto;
  final int? misPuntos;
  final List<LigaFila> tabla;
  final List<LigaMedallaCerrada> medallas;

  const LigaTemporadaCerrada({
    required this.ok,
    required this.mensaje,
    required this.temporada,
    required this.miPuesto,
    required this.misPuntos,
    required this.tabla,
    required this.medallas,
  });

  factory LigaTemporadaCerrada.fromJson(Map<String, dynamic> json) {
    final ok = json['ok'] == true;
    return LigaTemporadaCerrada(
      ok: ok,
      mensaje: json['mensaje']?.toString() ?? '',
      temporada: (json['temporada'] as Map?) == null
          ? null
          : LigaTemporadaCerradaInfo.fromJson(
              Map<String, dynamic>.from(json['temporada'] as Map),
            ),
      miPuesto: (json['miPuesto'] as num?)?.toInt(),
      misPuntos: (json['misPuntos'] as num?)?.toInt(),
      tabla: ((json['tabla'] as List?) ?? const [])
          .map((e) => LigaFila.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      medallas: ((json['medallas'] as List?) ?? const [])
          .map(
            (e) => LigaMedallaCerrada.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .whereType<LigaMedallaCerrada>()
          .toList(),
    );
  }
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
