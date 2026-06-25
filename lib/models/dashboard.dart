class Dashboard {

  final Resumen resumen;

  final Clubvision clubvision;

  final String tendencia;

  final String mood;

  final List<LibroMes> libroMes;

  final List<LeyendoAhora> leyendoAhora;

  Dashboard({
    required this.resumen,
    required this.clubvision,
    required this.tendencia,
    required this.mood,
    required this.libroMes,
    required this.leyendoAhora,
  });

  factory Dashboard.fromJson(
    Map<String, dynamic> json,
  ) {
    return Dashboard(

      resumen: Resumen.fromJson(
        json['resumen'] ?? {},
      ),

      clubvision: Clubvision.fromJson(
        json['clubvision'] ?? {},
      ),

      tendencia:
          json['tendencia'] ?? '',

      mood:
          json['mood'] ?? '',

      libroMes:
          (json['libroMes']
                      as List? ??
                  [])
              .map(
                (x) =>
                    LibroMes.fromJson(
                  x,
                ),
              )
              .toList(),

      leyendoAhora:
          (json['leyendoAhora']
                      as List? ??
                  [])
              .map(
                (x) =>
                    LeyendoAhora.fromJson(
                  x,
                ),
              )
              .toList(),
    );
  }
}

class Clubvision {

  final String estado;

  final String titulo;

  final String mensaje;

  final String ganador;

  final List<String> lectoras;

  Clubvision({
    required this.estado,
    required this.titulo,
    required this.mensaje,
    required this.ganador,
    required this.lectoras,
  });

  factory Clubvision.fromJson(
    Map<String, dynamic> json,
  ) {
    return Clubvision(

      estado:
          json['estado'] ?? '',

      titulo:
          json['titulo'] ?? '',

      mensaje:
          json['mensaje'] ?? '',

      ganador:
          json['ganador'] ?? '',

      lectoras:
          List<String>.from(
        json['lectoras'] ?? [],
      ),
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

  factory Resumen.fromJson(
    Map<String, dynamic> json,
  ) {
    return Resumen(

      usuarioMes:
          json['usuarioMes'] ?? '',

      librosUsuarioMes:
          json['librosUsuarioMes'] ?? 0,

      actividadMes:
          json['actividadMes'] ?? 0,

      valoracionMedia:
          json['valoracionMedia']
                  ?.toString() ??
              '',
    );
  }
}

class LibroMes {

  final String libro;

  final int puntos;

  LibroMes({
    required this.libro,
    required this.puntos,
  });

  factory LibroMes.fromJson(
    Map<String, dynamic> json,
  ) {
    return LibroMes(

      libro:
          json['libro'] ?? '',

      puntos:
          json['puntos'] ?? 0,
    );
  }
}

class LeyendoAhora {

  final String usuario;

  final List<String> libros;

  final int total;

  LeyendoAhora({
    required this.usuario,
    required this.libros,
    required this.total,
  });

  factory LeyendoAhora.fromJson(
    Map<String, dynamic> json,
  ) {
    return LeyendoAhora(

      usuario:
          json['usuario'] ?? '',

      libros:
          List<String>.from(
        json['libros'] ?? [],
      ),

      total:
          json['total'] ?? 0,
    );
  }
}