// models/perfil_usuario.dart

class PerfilUsuario {
  final String usuario;
  final String avatarUrl;
  final PerfilResumen resumen;
  final List<PerfilLibro> leyendo;
  final List<PerfilLibroTerminado> terminados;
  final List<PerfilLibroTerminado> abandonados;
  final List<PerfilLibro> pendientes;
  final List<PerfilGenero> generosFavoritos;

  PerfilUsuario({
    required this.usuario,
    required this.avatarUrl,
    required this.resumen,
    required this.leyendo,
    required this.terminados,
    required this.abandonados,
    required this.pendientes,
    required this.generosFavoritos,
  });

  factory PerfilUsuario.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(String key, T Function(Map<String, dynamic>) mapper) {
      return (json[key] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(mapper)
          .toList();
    }

    return PerfilUsuario(
      usuario: json['usuario']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      resumen: PerfilResumen.fromJson(
        json['resumen'] as Map<String, dynamic>? ?? const {},
      ),
      leyendo: parseList('leyendo', PerfilLibro.fromJson),
      terminados: parseList('terminados', PerfilLibroTerminado.fromJson),
      abandonados: parseList('abandonados', PerfilLibroTerminado.fromJson),
      pendientes: parseList('pendientes', PerfilLibro.fromJson),
      generosFavoritos: parseList('generosFavoritos', PerfilGenero.fromJson),
    );
  }
}

class PerfilResumen {
  final int terminados;
  final int leyendo;
  final int pendientes;
  final int abandonados;
  final double media;
  final int comentarios;
  final int likesRecibidos;

  PerfilResumen({
    required this.terminados,
    required this.leyendo,
    required this.pendientes,
    required this.abandonados,
    required this.media,
    required this.comentarios,
    required this.likesRecibidos,
  });

  factory PerfilResumen.fromJson(Map<String, dynamic> json) {
    return PerfilResumen(
      terminados: (json['terminados'] as num?)?.toInt() ?? 0,
      leyendo: (json['leyendo'] as num?)?.toInt() ?? 0,
      pendientes: (json['pendientes'] as num?)?.toInt() ?? 0,
      abandonados: (json['abandonados'] as num?)?.toInt() ?? 0,
      media: (json['media'] as num?)?.toDouble() ?? 0,
      comentarios: (json['comentarios'] as num?)?.toInt() ?? 0,
      likesRecibidos: (json['likesRecibidos'] as num?)?.toInt() ?? 0,
    );
  }
}

class PerfilLibro {
  final String libro;
  final String genero;

  PerfilLibro({required this.libro, required this.genero});

  factory PerfilLibro.fromJson(Map<String, dynamic> json) {
    return PerfilLibro(
      libro: json['libro']?.toString() ?? '',
      genero: json['genero']?.toString() ?? '',
    );
  }
}

class PerfilLibroTerminado {
  final String libraryId;
  final String bookId;

  final String libro;
  final String genero;
  final String fechaInicio;
  final String fechaFin;
  final String valoracion;
  final String resena;
  final String coverUrl;

  PerfilLibroTerminado({
    required this.libraryId,
    required this.bookId,
    required this.libro,
    required this.genero,
    required this.fechaInicio,
    required this.fechaFin,
    required this.valoracion,
    required this.resena,
    required this.coverUrl,
  });

  /// Compatibilidad temporal con código antiguo que todavía usa `fecha`.
  String get fecha => fechaFin;

  factory PerfilLibroTerminado.fromJson(Map<String, dynamic> json) {
    return PerfilLibroTerminado(
      libraryId: json['libraryId']?.toString() ?? json['id']?.toString() ?? '',
      bookId: json['bookId']?.toString() ?? '',
      libro: json['libro']?.toString() ?? '',
      genero: json['genero']?.toString() ?? '',
      fechaInicio:
          json['fechaInicio']?.toString() ??
          json['startedAt']?.toString() ??
          '',
      fechaFin:
          json['fechaFin']?.toString() ??
          json['finishedAt']?.toString() ??
          json['fecha']?.toString() ??
          '',
      valoracion: json['valoracion']?.toString() ?? '',
      resena: json['resena']?.toString() ?? json['review']?.toString() ?? '',
      coverUrl: json['coverUrl']?.toString() ?? '',
    );
  }
}

class PerfilGenero {
  final String genero;
  final int total;

  PerfilGenero({required this.genero, required this.total});

  factory PerfilGenero.fromJson(Map<String, dynamic> json) {
    return PerfilGenero(
      genero: json['genero']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}
