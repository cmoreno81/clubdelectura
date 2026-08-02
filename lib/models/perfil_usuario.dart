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
  final List<PerfilSaga> sagas;
  final List<PerfilMesLector> historicoMeses;

  PerfilUsuario({
    required this.usuario,
    required this.avatarUrl,
    required this.resumen,
    required this.leyendo,
    required this.terminados,
    required this.abandonados,
    required this.pendientes,
    required this.generosFavoritos,
    required this.sagas,
    required this.historicoMeses,
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
      sagas: parseList('sagas', PerfilSaga.fromJson),
      historicoMeses: parseList('historicoMeses', PerfilMesLector.fromJson),
    );
  }
}

class PerfilResumen {
  final int terminados;
  final int relecturas;
  final int leyendo;
  final int pendientes;
  final int abandonados;
  final double media;
  final int comentarios;
  final int likesRecibidos;
  final int clubes;
  final int sagasAbiertas;

  PerfilResumen({
    required this.terminados,
    required this.relecturas,
    required this.leyendo,
    required this.pendientes,
    required this.abandonados,
    required this.media,
    required this.comentarios,
    required this.likesRecibidos,
    required this.clubes,
    required this.sagasAbiertas,
  });

  factory PerfilResumen.fromJson(Map<String, dynamic> json) {
    return PerfilResumen(
      terminados: (json['terminados'] as num?)?.toInt() ?? 0,
      relecturas: (json['relecturas'] as num?)?.toInt() ?? 0,
      leyendo: (json['leyendo'] as num?)?.toInt() ?? 0,
      pendientes: (json['pendientes'] as num?)?.toInt() ?? 0,
      abandonados: (json['abandonados'] as num?)?.toInt() ?? 0,
      media: (json['media'] as num?)?.toDouble() ?? 0,
      comentarios: (json['comentarios'] as num?)?.toInt() ?? 0,
      likesRecibidos: (json['likesRecibidos'] as num?)?.toInt() ?? 0,
      clubes: (json['clubes'] as num?)?.toInt() ?? 0,
      sagasAbiertas: (json['sagasAbiertas'] as num?)?.toInt() ?? 0,
    );
  }
}

class PerfilLibro {
  final String libraryId;
  final String bookId;
  final String libro;
  final String genero;
  final String fechaInicio;
  final String coverUrl;
  final bool esRelectura;

  PerfilLibro({
    required this.libraryId,
    required this.bookId,
    required this.libro,
    required this.genero,
    required this.fechaInicio,
    required this.coverUrl,
    required this.esRelectura,
  });

  factory PerfilLibro.fromJson(Map<String, dynamic> json) {
    return PerfilLibro(
      libraryId: json['libraryId']?.toString() ?? json['id']?.toString() ?? '',
      bookId: json['bookId']?.toString() ?? '',
      libro: json['libro']?.toString() ?? '',
      genero: json['genero']?.toString() ?? '',
      fechaInicio:
          json['fechaInicio']?.toString() ??
          json['startedAt']?.toString() ??
          '',
      coverUrl: json['coverUrl']?.toString() ?? '',
      esRelectura: json['esRelectura'] == true,
    );
  }
}

class PerfilLibroTerminado {
  final String completionId;
  final String libraryId;
  final String bookId;

  final String libro;
  final String genero;
  final String fechaInicio;
  final String fechaFin;
  final String valoracion;
  final String resena;
  final String coverUrl;
  final bool esRelectura;

  PerfilLibroTerminado({
    required this.completionId,
    required this.libraryId,
    required this.bookId,
    required this.libro,
    required this.genero,
    required this.fechaInicio,
    required this.fechaFin,
    required this.valoracion,
    required this.resena,
    required this.coverUrl,
    required this.esRelectura,
  });

  /// Compatibilidad temporal con código antiguo que todavía usa `fecha`.
  String get fecha => fechaFin;

  factory PerfilLibroTerminado.fromJson(Map<String, dynamic> json) {
    return PerfilLibroTerminado(
      completionId: json['completionId']?.toString() ?? '',
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
      esRelectura: json['esRelectura'] == true,
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

class PerfilSaga {
  const PerfilSaga({
    required this.id,
    required this.nombre,
    required this.autor,
    required this.leidos,
    required this.totalConocidos,
    required this.totalSaga,
    required this.estado,
    required this.estadoEditorial,
    required this.volumenes,
    this.siguiente,
  });

  final String id;
  final String nombre;
  final String autor;
  final int leidos;
  final int totalConocidos;
  final int totalSaga;
  final String estado;
  final String estadoEditorial;
  final List<PerfilSagaVolumen> volumenes;
  final PerfilSagaVolumen? siguiente;

  bool get completada => estado == 'COMPLETADA';
  bool get alDia => estado == 'AL_DIA';
  bool get pendiente => estado == 'PENDIENTE';
  bool get abandonada => estado == 'ABANDONADA';

  factory PerfilSaga.fromJson(Map<String, dynamic> json) {
    final siguiente = json['siguiente'];
    final leidos = (json['leidos'] as num?)?.toInt() ?? 0;
    final totalConocidos = (json['totalConocidos'] as num?)?.toInt() ?? 0;
    final totalSaga = (json['totalSaga'] as num?)?.toInt() ?? 0;
    final totalNecesario = totalSaga > totalConocidos
        ? totalSaga
        : totalConocidos;
    final estadoRecibido = json['estado']?.toString() ?? 'EN_CURSO';
    final estado =
        estadoRecibido == 'COMPLETADA' &&
            (totalNecesario <= 0 || leidos < totalNecesario)
        ? leidos > 0
              ? 'EN_CURSO'
              : 'PENDIENTE'
        // ABANDONADA llega siempre del backend sin necesidad de reinterpretarla
        : estadoRecibido;

    return PerfilSaga(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      autor: json['autor']?.toString() ?? '',
      leidos: leidos,
      totalConocidos: totalConocidos,
      totalSaga: totalSaga,
      estado: estado,
      estadoEditorial: json['estadoEditorial']?.toString() ?? 'UNKNOWN',
      volumenes: (json['volumenes'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PerfilSagaVolumen.fromJson)
          .toList(growable: false),
      siguiente: siguiente is Map<String, dynamic>
          ? PerfilSagaVolumen.fromJson(siguiente)
          : null,
    );
  }
}

class PerfilSagaVolumen {
  const PerfilSagaVolumen({
    required this.bookId,
    required this.titulo,
    required this.numero,
    required this.posicion,
    required this.coverUrl,
    required this.estado,
  });

  final String bookId;
  final String titulo;
  final String numero;
  final int? posicion;
  final String coverUrl;
  final String estado;

  factory PerfilSagaVolumen.fromJson(Map<String, dynamic> json) =>
      PerfilSagaVolumen(
        bookId: json['bookId']?.toString() ?? '',
        titulo: json['titulo']?.toString() ?? '',
        numero: json['numero']?.toString() ?? '',
        posicion: (json['posicion'] as num?)?.toInt(),
        coverUrl: json['coverUrl']?.toString() ?? '',
        estado: json['estado']?.toString() ?? 'NO_ANADIDO',
      );

  bool get esLeidoExterno => estado == 'LEIDO_EXTERNO';
  bool get esOmitido => estado == 'OMITIDO';
  bool get esNoAnadido => estado == 'NO_ANADIDO';

  /// Cuenta como cubierto para el progreso de la saga
  bool get estaCubierto =>
      estado == 'LEIDO' || estado == 'LEIDO_EXTERNO' || estado == 'OMITIDO';
}

// ─────────────────────────────────────────────
// Histórico de meses lectores
// ─────────────────────────────────────────────

class PerfilMesLector {
  const PerfilMesLector({
    required this.anio,
    required this.mes,
    required this.lecturas,
  });

  final int anio;
  final int mes;
  final List<PerfilMesLectura> lecturas;

  factory PerfilMesLector.fromJson(Map<String, dynamic> json) =>
      PerfilMesLector(
        anio: (json['anio'] as num?)?.toInt() ?? 0,
        mes: (json['mes'] as num?)?.toInt() ?? 0,
        lecturas: (json['lecturas'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(PerfilMesLectura.fromJson)
            .toList(growable: false),
      );
}

class PerfilMesLectura {
  const PerfilMesLectura({
    required this.id,
    required this.bookId,
    required this.titulo,
    required this.coverUrl,
    required this.fechaInicio,
    required this.fechaFin,
    this.valoracion,
  });

  final String id;
  final String bookId;
  final String titulo;
  final String coverUrl;
  final String fechaInicio;
  final String fechaFin;
  final double? valoracion;

  factory PerfilMesLectura.fromJson(Map<String, dynamic> json) =>
      PerfilMesLectura(
        id: json['id']?.toString() ?? '',
        bookId: json['bookId']?.toString() ?? '',
        titulo: json['titulo']?.toString() ?? '',
        coverUrl: json['coverUrl']?.toString() ?? '',
        fechaInicio: json['fechaInicio']?.toString() ?? '',
        fechaFin: json['fechaFin']?.toString() ?? '',
        valoracion: json['valoracion'] != null
            ? (json['valoracion'] as num).toDouble()
            : null,
      );
}
