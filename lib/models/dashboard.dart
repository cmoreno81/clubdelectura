import 'lectura_actual.dart';
import 'reaccion_comentario.dart';

class Dashboard {
  final Resumen resumen;

  final Clubvision clubvision;

  final String tendencia;

  final String mood;

  final List<LibroMes> libroMes;

  final List<LeyendoAhora> leyendoAhora;

  final LecturaActual lecturaActual;

  Dashboard({
    required this.resumen,
    required this.clubvision,
    required this.tendencia,
    required this.mood,
    required this.libroMes,
    required this.leyendoAhora,
    required this.lecturaActual,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    return Dashboard(
      resumen: Resumen.fromJson(json['resumen'] ?? {}),

      clubvision: Clubvision.fromJson(json['clubvision'] ?? {}),

      tendencia: json['tendencia']?.toString() ?? '',

      mood: json['mood']?.toString() ?? '',

      libroMes: (json['libroMes'] as List? ?? [])
          .map((x) => LibroMes.fromJson(x))
          .toList(),

      leyendoAhora: (json['leyendoAhora'] as List? ?? [])
          .map((x) => LeyendoAhora.fromJson(x))
          .toList(),

      lecturaActual: LecturaActual.fromJson(json['lecturaActual'] ?? {}),
    );
  }
}

class Clubvision {
  final String estado;

  final String titulo;

  final String mensaje;

  final String ganador;

  final String idVotacion;

  final List<String> lectoras;

  final int totalCandidatas;

  final int votosRecibidos;
  final int totalUsuarios;
  final int votosPendientes;
  final int porcentaje;
  final int comentarios;
  final int likes;
  final String ultimaActividad;

  Clubvision({
    required this.estado,
    required this.titulo,
    required this.mensaje,
    required this.ganador,
    required this.lectoras,
    required this.idVotacion,
    required this.totalCandidatas,
    required this.votosRecibidos,
    required this.totalUsuarios,
    required this.votosPendientes,
    required this.porcentaje,
    required this.comentarios,
    required this.likes,
    required this.ultimaActividad,
  });

  factory Clubvision.fromJson(Map<String, dynamic> json) {
    return Clubvision(
      estado: json['estado']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      mensaje: json['mensaje']?.toString() ?? '',
      ganador: json['ganador']?.toString() ?? '',
      idVotacion: json['idVotacion']?.toString() ?? '',
      lectoras: List<String>.from(json['lectoras'] ?? []),
      totalCandidatas: (json['totalCandidatas'] as num?)?.toInt() ?? 0,
      votosRecibidos: (json['votosRecibidos'] as num?)?.toInt() ?? 0,

      totalUsuarios: (json['totalUsuarios'] as num?)?.toInt() ?? 0,

      votosPendientes: (json['votosPendientes'] as num?)?.toInt() ?? 0,

      porcentaje: (json['porcentaje'] as num?)?.toInt() ?? 0,

      comentarios: (json['comentarios'] as num?)?.toInt() ?? 0,

      likes: (json['likes'] as num?)?.toInt() ?? 0,

      ultimaActividad: json['ultimaActividad']?.toString() ?? '',
    );
  }
}

class Resumen {
  final String usuarioMes;

  final int librosUsuarioMes;

  final int actividadMes;

  final String valoracionMedia;

  Resumen({
    required this.usuarioMes,
    required this.librosUsuarioMes,
    required this.actividadMes,
    required this.valoracionMedia,
  });

  factory Resumen.fromJson(Map<String, dynamic> json) {
    return Resumen(
      usuarioMes: json['usuarioMes']?.toString() ?? '',
      librosUsuarioMes: (json['librosUsuarioMes'] as num?)?.toInt() ?? 0,
      actividadMes: (json['actividadMes'] as num?)?.toInt() ?? 0,
      valoracionMedia: json['valoracionMedia']?.toString() ?? '',
    );
  }
}

class LibroMes {
  final String libro;

  final int puntos;

  LibroMes({required this.libro, required this.puntos});

  factory LibroMes.fromJson(Map<String, dynamic> json) {
    return LibroMes(
      libro: json['libro']?.toString() ?? '',
      puntos: (json['puntos'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeyendoAhora {
  final String usuario;
  final String avatarUrl;
  final List<String> libros;
  final List<LecturaAhoraItem> lecturas;

  final int total;

  LeyendoAhora({
    required this.usuario,
    required this.libros,
    required this.total,
    required this.avatarUrl,
    required this.lecturas,
  });
  factory LeyendoAhora.fromJson(Map<String, dynamic> json) {
    final libros = List<String>.from(json['libros'] ?? []);
    final lecturasNuevas = (json['lecturas'] as List? ?? const [])
        .map(
          (item) =>
              LecturaAhoraItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();

    return LeyendoAhora(
      usuario: json['usuario']?.toString() ?? '',
      libros: libros,
      lecturas: lecturasNuevas.isNotEmpty
          ? lecturasNuevas
          : libros
                .map(
                  (titulo) => LecturaAhoraItem(
                    libraryId: '',
                    bookId: '',
                    titulo: titulo,
                    coverUrl: '',
                    progreso: 0,
                    paginaActual: null,
                    paginasTotales: null,
                    comentario: '',
                    actualizadoEn: null,
                    reacciones: const {},
                    miReaccion: null,
                  ),
                )
                .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      avatarUrl: json['avatarUrl']?.toString() ?? '',
    );
  }
}

class LecturaAhoraItem {
  final String libraryId;
  final String bookId;
  final String titulo;
  final String coverUrl;
  final int progreso;
  final int? paginaActual;
  final int? paginasTotales;
  final String comentario;
  final DateTime? actualizadoEn;
  final Map<ReaccionComentario, int> reacciones;
  final ReaccionComentario? miReaccion;

  const LecturaAhoraItem({
    required this.libraryId,
    required this.bookId,
    required this.titulo,
    required this.coverUrl,
    required this.progreso,
    required this.paginaActual,
    required this.paginasTotales,
    required this.comentario,
    required this.actualizadoEn,
    required this.reacciones,
    required this.miReaccion,
  });

  factory LecturaAhoraItem.fromJson(
    Map<String, dynamic> json,
  ) => LecturaAhoraItem(
    libraryId: json['libraryId']?.toString() ?? '',
    bookId: json['bookId']?.toString() ?? '',
    titulo: json['titulo']?.toString() ?? '',
    coverUrl: json['coverUrl']?.toString() ?? '',
    progreso: ((json['progreso'] as num?)?.toInt() ?? 0).clamp(0, 100),
    paginaActual: (json['paginaActual'] as num?)?.toInt(),
    paginasTotales: (json['paginasTotales'] as num?)?.toInt(),
    comentario: json['comentario']?.toString() ?? '',
    actualizadoEn: DateTime.tryParse(json['actualizadoEn']?.toString() ?? ''),
    reacciones: {
      for (final reaccion in ReaccionComentario.values)
        reaccion:
            ((json['reacciones'] as Map?)?[reaccion.apiValue] as num?)
                ?.toInt() ??
            0,
    },
    miReaccion: ReaccionComentarioDatos.fromApi(json['miReaccion']?.toString()),
  );
}
