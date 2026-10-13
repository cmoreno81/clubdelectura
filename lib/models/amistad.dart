import 'reaccion_comentario.dart';

/// Una persona en la lista de amistades o en una solicitud.
class PersonaAmistad {
  const PersonaAmistad({required this.nombre, this.avatarUrl = ''});

  final String nombre;
  final String avatarUrl;

  factory PersonaAmistad.fromJson(Map<String, dynamic> json) => PersonaAmistad(
    nombre: json['nombre']?.toString() ?? '',
    avatarUrl: json['avatarUrl']?.toString() ?? '',
  );
}

/// Cómo está la relación con una persona que sale en una búsqueda.
enum EstadoAmistad {
  ninguna,
  enviada,
  recibida,
  amiga;

  static EstadoAmistad desde(String? valor) => switch (valor) {
    'ENVIADA' => EstadoAmistad.enviada,
    'RECIBIDA' => EstadoAmistad.recibida,
    'AMIGA' => EstadoAmistad.amiga,
    _ => EstadoAmistad.ninguna,
  };
}

class PersonaBuscada extends PersonaAmistad {
  const PersonaBuscada({
    required super.nombre,
    super.avatarUrl,
    this.estado = EstadoAmistad.ninguna,
  });

  final EstadoAmistad estado;

  factory PersonaBuscada.fromJson(Map<String, dynamic> json) => PersonaBuscada(
    nombre: json['nombre']?.toString() ?? '',
    avatarUrl: json['avatarUrl']?.toString() ?? '',
    estado: EstadoAmistad.desde(json['estado']?.toString()),
  );
}

/// Qué dejas ver a tus amistades de ti.
class PrivacidadAmistades {
  const PrivacidadAmistades({
    this.leyendo = true,
    this.biblioteca = true,
    this.resenas = true,
    this.deseos = true,
  });

  final bool leyendo;
  final bool biblioteca;
  final bool resenas;
  final bool deseos;

  factory PrivacidadAmistades.fromJson(Map<String, dynamic> json) =>
      PrivacidadAmistades(
        leyendo: json['leyendo'] != false,
        biblioteca: json['biblioteca'] != false,
        resenas: json['resenas'] != false,
        deseos: json['deseos'] != false,
      );

  PrivacidadAmistades copyWith({
    bool? leyendo,
    bool? biblioteca,
    bool? resenas,
    bool? deseos,
  }) => PrivacidadAmistades(
    leyendo: leyendo ?? this.leyendo,
    biblioteca: biblioteca ?? this.biblioteca,
    resenas: resenas ?? this.resenas,
    deseos: deseos ?? this.deseos,
  );
}

class AmistadesData {
  const AmistadesData({
    this.miCodigo = '',
    this.privacidad = const PrivacidadAmistades(),
    this.amistades = const [],
    this.recibidas = const [],
    this.enviadas = const [],
  });

  final String miCodigo;
  final PrivacidadAmistades privacidad;
  final List<PersonaAmistad> amistades;
  final List<PersonaAmistad> recibidas;
  final List<PersonaAmistad> enviadas;

  AmistadesData conPrivacidad(PrivacidadAmistades nueva) => AmistadesData(
    miCodigo: miCodigo,
    privacidad: nueva,
    amistades: amistades,
    recibidas: recibidas,
    enviadas: enviadas,
  );

  factory AmistadesData.fromJson(Map<String, dynamic> json) {
    List<PersonaAmistad> lista(String clave) => (json[clave] as List? ?? [])
        .whereType<Map>()
        .map((e) => PersonaAmistad.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return AmistadesData(
      miCodigo: json['miCodigo']?.toString() ?? '',
      privacidad: json['privacidad'] is Map
          ? PrivacidadAmistades.fromJson(
              Map<String, dynamic>.from(json['privacidad'] as Map),
            )
          : const PrivacidadAmistades(),
      amistades: lista('amistades'),
      recibidas: lista('recibidas'),
      enviadas: lista('enviadas'),
    );
  }
}

/// Respuesta de una acción de amistad: si salió bien y el mensaje para la persona.
class ResultadoAmistad {
  const ResultadoAmistad({
    required this.ok,
    this.mensaje = '',
    this.estado,
    this.enviadas = 0,
    this.yaRecomendado = 0,
  });

  final bool ok;
  final String mensaje;
  final EstadoAmistad? estado;

  /// Recomendaciones: cuántas se han enviado y a cuántas ya se les había
  /// recomendado ese libro hace poco.
  final int enviadas;
  final int yaRecomendado;
}

Map<ReaccionComentario, int> _leerReacciones(dynamic raw) {
  final mapa = raw is Map ? raw : const {};
  return {
    for (final r in ReaccionComentario.values)
      r: (mapa[r.apiValue] as num?)?.toInt() ?? 0,
  };
}

/// Lo que una amistad está leyendo ahora, con su progreso y las reacciones.
class LecturaAmistad {
  const LecturaAmistad({
    required this.libraryId,
    required this.bookId,
    required this.titulo,
    this.autor = '',
    this.coverUrl = '',
    this.estado = 'LEYENDO',
    this.progreso = 0,
    this.paginaActual,
    this.paginasTotales,
    this.nota = '',
    this.reacciones = const {},
    this.miReaccion,
  });

  final String libraryId;
  final String bookId;
  final String titulo;
  final String autor;
  final String coverUrl;
  final String estado;
  final int progreso;
  final int? paginaActual;
  final int? paginasTotales;
  final String nota;
  final Map<ReaccionComentario, int> reacciones;
  final ReaccionComentario? miReaccion;

  factory LecturaAmistad.fromJson(Map<String, dynamic> json) => LecturaAmistad(
    libraryId: json['libraryId']?.toString() ?? '',
    bookId: json['bookId']?.toString() ?? '',
    titulo: json['titulo']?.toString() ?? '',
    autor: json['autor']?.toString() ?? '',
    coverUrl: json['coverUrl']?.toString() ?? '',
    estado: json['estado']?.toString() ?? 'LEYENDO',
    progreso: (json['progreso'] as num?)?.toInt() ?? 0,
    paginaActual: (json['paginaActual'] as num?)?.toInt(),
    paginasTotales: (json['paginasTotales'] as num?)?.toInt(),
    nota: json['nota']?.toString() ?? '',
    reacciones: _leerReacciones(json['reacciones']),
    miReaccion: ReaccionComentarioDatos.fromApi(json['miReaccion']?.toString()),
  );

  LecturaAmistad conReaccion({
    required Map<ReaccionComentario, int> reacciones,
    required ReaccionComentario? miReaccion,
  }) => LecturaAmistad(
    libraryId: libraryId,
    bookId: bookId,
    titulo: titulo,
    autor: autor,
    coverUrl: coverUrl,
    estado: estado,
    progreso: progreso,
    paginaActual: paginaActual,
    paginasTotales: paginasTotales,
    nota: nota,
    reacciones: reacciones,
    miReaccion: miReaccion,
  );
}

class LibroDeAmistad {
  const LibroDeAmistad({
    required this.bookId,
    required this.titulo,
    this.coverUrl = '',
    this.valoracion,
    this.texto = '',
    this.contieneSpoilers = false,
    this.autor = '',
    this.prioridad = '',
  });

  final String bookId;
  final String titulo;
  final String coverUrl;
  final double? valoracion;
  final String texto;
  final bool contieneSpoilers;

  /// Solo en la lista de deseos: autoría y prioridad (`HIGH`, `MEDIUM`, `LOW`).
  final String autor;
  final String prioridad;

  factory LibroDeAmistad.fromJson(Map<String, dynamic> json) => LibroDeAmistad(
    bookId: json['bookId']?.toString() ?? '',
    titulo: json['titulo']?.toString() ?? '',
    coverUrl: json['coverUrl']?.toString() ?? '',
    valoracion: (json['valoracion'] as num?)?.toDouble(),
    texto: json['texto']?.toString() ?? '',
    contieneSpoilers: json['contieneSpoilers'] == true,
    autor: json['autor']?.toString() ?? '',
    prioridad: json['prioridad']?.toString() ?? '',
  );
}

/// El perfil de una amistad, con lo que ha decidido compartir.
class PerfilAmistad {
  const PerfilAmistad({
    required this.nombre,
    this.avatarUrl = '',
    this.bio = '',
    this.compartido = const PrivacidadAmistades(),
    this.leyendo = const [],
    this.terminados = const [],
    this.pendientes = const [],
    this.resenas = const [],
    this.deseos = const [],
    this.totalPendientes,
    this.totalTerminados,
  });

  final String nombre;
  final String avatarUrl;
  final String bio;
  final PrivacidadAmistades compartido;
  final List<LecturaAmistad> leyendo;
  final List<LibroDeAmistad> terminados;
  final List<LibroDeAmistad> pendientes;
  final List<LibroDeAmistad> resenas;
  final List<LibroDeAmistad> deseos;
  final int? totalPendientes;
  final int? totalTerminados;

  factory PerfilAmistad.fromJson(Map<String, dynamic> json) {
    List<T> lista<T>(String clave, T Function(Map<String, dynamic>) crear) =>
        (json[clave] as List? ?? [])
            .whereType<Map>()
            .map((e) => crear(Map<String, dynamic>.from(e)))
            .toList();
    return PerfilAmistad(
      nombre: json['nombre']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      compartido: json['compartido'] is Map
          ? PrivacidadAmistades.fromJson(
              Map<String, dynamic>.from(json['compartido'] as Map),
            )
          : const PrivacidadAmistades(),
      leyendo: lista('leyendo', LecturaAmistad.fromJson),
      terminados: lista('terminados', LibroDeAmistad.fromJson),
      pendientes: lista('pendientes', LibroDeAmistad.fromJson),
      resenas: lista('resenas', LibroDeAmistad.fromJson),
      deseos: lista('deseos', LibroDeAmistad.fromJson),
      totalPendientes: (json['totalPendientes'] as num?)?.toInt(),
      totalTerminados: (json['totalTerminados'] as num?)?.toInt(),
    );
  }
}

/// Una novedad de la gente a la que sigues: está leyendo algo o lo ha terminado.
class ActividadAmistad {
  const ActividadAmistad({
    required this.tipo,
    required this.nombre,
    this.avatarUrl = '',
    required this.bookId,
    required this.titulo,
    this.coverUrl = '',
    this.valoracion,
    this.lectura,
  });

  /// `LEYENDO` o `TERMINADO`.
  final String tipo;
  final String nombre;
  final String avatarUrl;
  final String bookId;
  final String titulo;
  final String coverUrl;
  final double? valoracion;

  /// Solo en `LEYENDO`: progreso y reacciones.
  final LecturaAmistad? lectura;

  bool get esLectura => tipo == 'LEYENDO';

  factory ActividadAmistad.fromJson(Map<String, dynamic> json) {
    final tipo = json['tipo']?.toString() ?? '';
    return ActividadAmistad(
      tipo: tipo,
      nombre: json['nombre']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      bookId: json['bookId']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      coverUrl: json['coverUrl']?.toString() ?? '',
      valoracion: (json['valoracion'] as num?)?.toDouble(),
      lectura: tipo == 'LEYENDO' ? LecturaAmistad.fromJson(json) : null,
    );
  }
}
