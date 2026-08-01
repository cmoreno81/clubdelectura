class MoodClub {
  final String titular;
  final String narrador;
  final List<String> estados;
  final List<ActividadClub> actividad;
  final MoodSemanal moodSemanal;
  final ResumenMood resumen;
  final ConversacionMood? conversacionDestacada;
  final LibroMood? libroActivo;

  const MoodClub({
    required this.titular,
    required this.narrador,
    required this.estados,
    required this.actividad,
    required this.moodSemanal,
    required this.resumen,
    required this.conversacionDestacada,
    required this.libroActivo,
  });

  factory MoodClub.fromJson(Map<String, dynamic> json) {
    return MoodClub(
      titular: json['titular']?.toString() ?? '',
      narrador: json['narrador']?.toString() ?? '',
      estados: List<String>.from(json['estados'] as List? ?? const []),
      actividad: (json['actividad'] as List? ?? const [])
          .map((e) => ActividadClub.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      moodSemanal: MoodSemanal.fromJson(
        Map<String, dynamic>.from(json['moodSemanal'] as Map? ?? const {}),
      ),
      resumen: ResumenMood.fromJson(
        Map<String, dynamic>.from(json['resumen'] as Map? ?? const {}),
      ),
      conversacionDestacada: json['conversacionDestacada'] is Map
          ? ConversacionMood.fromJson(
              Map<String, dynamic>.from(json['conversacionDestacada']),
            )
          : null,
      libroActivo: json['libroActivo'] is Map
          ? LibroMood.fromJson(Map<String, dynamic>.from(json['libroActivo']))
          : null,
    );
  }
}

class MoodSemanal {
  final String? miMood;
  final int total;
  final Map<String, int> distribucion;
  final Map<String, List<String>> votantes;

  const MoodSemanal({
    required this.miMood,
    required this.total,
    required this.distribucion,
    this.votantes = const {},
  });

  factory MoodSemanal.fromJson(Map<String, dynamic> json) {
    final raw = json['distribucion'] as Map? ?? const {};
    final rawVotantes = json['votantes'] as Map? ?? const {};
    return MoodSemanal(
      miMood: json['miMood']?.toString(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      distribucion: {
        for (final entry in raw.entries)
          entry.key.toString(): (entry.value as num?)?.toInt() ?? 0,
      },
      votantes: {
        for (final entry in rawVotantes.entries)
          entry.key.toString(): List<String>.from(entry.value as List? ?? []),
      },
    );
  }
}

class ResumenMood {
  final int comentarios;
  final int reacciones;
  final int terminados;
  final int lectorasActivas;

  const ResumenMood({
    required this.comentarios,
    required this.reacciones,
    required this.terminados,
    required this.lectorasActivas,
  });

  factory ResumenMood.fromJson(Map<String, dynamic> json) => ResumenMood(
    comentarios: (json['comentariosSemana'] as num?)?.toInt() ?? 0,
    reacciones: (json['reaccionesSemana'] as num?)?.toInt() ?? 0,
    terminados: (json['terminadosSemana'] as num?)?.toInt() ?? 0,
    lectorasActivas: (json['lectorasActivas'] as num?)?.toInt() ?? 0,
  );
}

class ConversacionMood {
  final String usuario;
  final String texto;
  final String libro;
  final String capitulo;
  final int reacciones;
  final int respuestas;

  const ConversacionMood({
    required this.usuario,
    required this.texto,
    required this.libro,
    required this.capitulo,
    required this.reacciones,
    required this.respuestas,
  });

  factory ConversacionMood.fromJson(Map<String, dynamic> json) =>
      ConversacionMood(
        usuario: json['usuario']?.toString() ?? '',
        texto: json['texto']?.toString() ?? '',
        libro: json['libro']?.toString() ?? '',
        capitulo: json['capitulo']?.toString() ?? '',
        reacciones: (json['reacciones'] as num?)?.toInt() ?? 0,
        respuestas: (json['respuestas'] as num?)?.toInt() ?? 0,
      );
}

class LibroMood {
  final String libro;
  final String coverUrl;
  final int comentarios;
  final int reacciones;

  const LibroMood({
    required this.libro,
    required this.coverUrl,
    required this.comentarios,
    required this.reacciones,
  });

  factory LibroMood.fromJson(Map<String, dynamic> json) => LibroMood(
    libro: json['libro']?.toString() ?? '',
    coverUrl: json['coverUrl']?.toString() ?? '',
    comentarios: (json['comentarios'] as num?)?.toInt() ?? 0,
    reacciones: (json['reacciones'] as num?)?.toInt() ?? 0,
  );
}

class ActividadClub {
  final String icono;
  final String texto;
  final String tipo;
  final String bookId;
  final String libro;
  final String coverUrl;
  final String capitulo;

  const ActividadClub({
    required this.icono,
    required this.texto,
    required this.tipo,
    required this.bookId,
    required this.libro,
    required this.coverUrl,
    required this.capitulo,
  });

  factory ActividadClub.fromJson(Map<String, dynamic> json) => ActividadClub(
    icono: json['icono']?.toString() ?? '',
    texto: json['texto']?.toString() ?? '',
    tipo: json['tipo']?.toString() ?? '',
    bookId: json['bookId']?.toString() ?? '',
    libro: json['libro']?.toString() ?? '',
    coverUrl: json['coverUrl']?.toString() ?? '',
    capitulo: json['capitulo']?.toString() ?? '',
  );
}
