import 'reaccion_comentario.dart';

/// Una persona en la lista de amistades o en una solicitud.
class PersonaAmistad {
  const PersonaAmistad({
    required this.nombre,
    this.avatarUrl = '',
    this.clubEnComun = '',
  });

  final String nombre;
  final String avatarUrl;

  /// Nombre de un club que ya compartes con esta persona ('' si ninguno).
  final String clubEnComun;

  factory PersonaAmistad.fromJson(Map<String, dynamic> json) => PersonaAmistad(
    nombre: json['nombre']?.toString() ?? '',
    avatarUrl: json['avatarUrl']?.toString() ?? '',
    clubEnComun: json['clubEnComun']?.toString() ?? '',
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
    super.clubEnComun,
    this.estado = EstadoAmistad.ninguna,
  });

  final EstadoAmistad estado;

  factory PersonaBuscada.fromJson(Map<String, dynamic> json) => PersonaBuscada(
    nombre: json['nombre']?.toString() ?? '',
    avatarUrl: json['avatarUrl']?.toString() ?? '',
    clubEnComun: json['clubEnComun']?.toString() ?? '',
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
    this.clubId = '',
    this.libro = '',
    this.yaExistia = false,
  });

  final bool ok;
  final String mensaje;
  final EstadoAmistad? estado;

  /// Recomendaciones: cuántas se han enviado y a cuántas ya se les había
  /// recomendado ese libro hace poco.
  final int enviadas;
  final int yaRecomendado;

  /// Lecturas con amistades: el grupo creado o aceptado y si ya existía.
  final String clubId;
  final String libro;
  final bool yaExistia;
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
    this.id = '',
    this.reservado = false,
    this.reservadoPorMi = false,
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

  /// Solo en la lista de deseos: identificador del deseo y si otra amistad (o tú)
  /// ya lo ha reservado para regalar. Quien tiene la lista nunca lo ve.
  final String id;
  final bool reservado;
  final bool reservadoPorMi;

  factory LibroDeAmistad.fromJson(Map<String, dynamic> json) => LibroDeAmistad(
    bookId: json['bookId']?.toString() ?? '',
    titulo: json['titulo']?.toString() ?? '',
    coverUrl: json['coverUrl']?.toString() ?? '',
    valoracion: (json['valoracion'] as num?)?.toDouble(),
    texto: json['texto']?.toString() ?? '',
    contieneSpoilers: json['contieneSpoilers'] == true,
    autor: json['autor']?.toString() ?? '',
    prioridad: json['prioridad']?.toString() ?? '',
    id: json['id']?.toString() ?? '',
    reservado: json['reservado'] == true,
    reservadoPorMi: json['reservadoPorMi'] == true,
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

/// Un comentario en el progreso de una lectura.
class ComentarioProgreso {
  const ComentarioProgreso({
    required this.id,
    required this.autor,
    this.avatarUrl = '',
    required this.texto,
    this.fecha,
    this.esMio = false,
    this.puedoBorrar = false,
  });

  final String id;
  final String autor;
  final String avatarUrl;
  final String texto;
  final DateTime? fecha;
  final bool esMio;
  final bool puedoBorrar;

  factory ComentarioProgreso.fromJson(Map<String, dynamic> json) =>
      ComentarioProgreso(
        id: json['id']?.toString() ?? '',
        autor: json['autor']?.toString() ?? '',
        avatarUrl: json['avatarUrl']?.toString() ?? '',
        texto: json['texto']?.toString() ?? '',
        fecha: DateTime.tryParse(json['fecha']?.toString() ?? '')?.toLocal(),
        esMio: json['esMio'] == true,
        puedoBorrar: json['puedoBorrar'] == true,
      );
}

/// Comentarios de una lectura y si quien mira es la persona que la lee.
class ComentariosProgresoData {
  const ComentariosProgresoData({
    this.titulo = '',
    this.soyDuena = false,
    this.comentarios = const [],
  });

  final String titulo;
  final bool soyDuena;
  final List<ComentarioProgreso> comentarios;

  factory ComentariosProgresoData.fromJson(Map<String, dynamic> json) =>
      ComentariosProgresoData(
        titulo: json['titulo']?.toString() ?? '',
        soyDuena: json['soyDuena'] == true,
        comentarios: (json['comentarios'] as List? ?? [])
            .whereType<Map>()
            .map(
              (e) => ComentarioProgreso.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList(),
      );
}

/// Invitación recibida para leer un libro a la vez con una amistad.
class InvitacionLecturaAmistad {
  const InvitacionLecturaAmistad({
    required this.clubId,
    required this.bookId,
    required this.libro,
    required this.de,
    this.avatarUrl = '',
  });

  final String clubId;
  final String bookId;
  final String libro;
  final String de;
  final String avatarUrl;

  factory InvitacionLecturaAmistad.fromJson(Map<String, dynamic> json) =>
      InvitacionLecturaAmistad(
        clubId: json['clubId']?.toString() ?? '',
        bookId: json['bookId']?.toString() ?? '',
        libro: json['libro']?.toString() ?? '',
        de: json['de']?.toString() ?? '',
        avatarUrl: json['avatarUrl']?.toString() ?? '',
      );
}

/// Una lectura a la vez con una amistad (`esperando`: aún no ha respondido).
class LecturaConAmistad {
  const LecturaConAmistad({
    required this.clubId,
    required this.bookId,
    required this.libro,
    required this.con,
    this.avatarUrl = '',
    this.esperando = false,
    this.salio = false,
    this.esDuena = false,
    this.terminada = false,
  });

  final String clubId;
  final String bookId;
  final String libro;
  final String con;
  final String avatarUrl;
  final bool esperando;

  /// La otra persona ya no está en la lectura (la conversación sigue para ti).
  final bool salio;

  /// Quien la abrió: puede eliminarla para las dos personas.
  final bool esDuena;

  /// Quienes siguen en ella han terminado el libro. La conversación se conserva.
  final bool terminada;

  factory LecturaConAmistad.fromJson(Map<String, dynamic> json) =>
      LecturaConAmistad(
        clubId: json['clubId']?.toString() ?? '',
        bookId: json['bookId']?.toString() ?? '',
        libro: json['libro']?.toString() ?? '',
        con: json['con']?.toString() ?? '',
        avatarUrl: json['avatarUrl']?.toString() ?? '',
        esperando: json['esperando'] == true,
        salio: json['salio'] == true,
        esDuena: json['esDuena'] == true,
        terminada: json['terminada'] == true,
      );
}

class LecturasAmistadesData {
  const LecturasAmistadesData({
    this.recibidas = const [],
    this.lecturas = const [],
  });

  final List<InvitacionLecturaAmistad> recibidas;
  final List<LecturaConAmistad> lecturas;

  bool get vacia => recibidas.isEmpty && lecturas.isEmpty;

  /// Lecturas que siguen en marcha (incluye las que esperan respuesta).
  List<LecturaConAmistad> get enCurso =>
      lecturas.where((l) => !l.terminada).toList();

  /// Lecturas terminadas, que se conservan para volver a consultarlas.
  List<LecturaConAmistad> get terminadas =>
      lecturas.where((l) => l.terminada).toList();

  factory LecturasAmistadesData.fromJson(Map<String, dynamic> json) {
    List<T> lista<T>(String clave, T Function(Map<String, dynamic>) crear) =>
        (json[clave] as List? ?? [])
            .whereType<Map>()
            .map((e) => crear(Map<String, dynamic>.from(e)))
            .toList();
    return LecturasAmistadesData(
      recibidas: lista('recibidas', InvitacionLecturaAmistad.fromJson),
      lecturas: lista('lecturas', LecturaConAmistad.fromJson),
    );
  }
}
