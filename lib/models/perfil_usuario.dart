// models/perfil_usuario.dart

class PerfilUsuario {
  final String usuario;
  final PerfilResumen resumen;
  final List<PerfilLibro> leyendo;
  final List<PerfilLibroTerminado> terminados;
  final List<PerfilLibro> abandonados;
  final List<PerfilLibro> pendientes;
  final List<PerfilGenero> generosFavoritos;

  PerfilUsuario({
    required this.usuario,
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
          .map((e) => mapper(e as Map<String, dynamic>))
          .toList();
    }

    return PerfilUsuario(
      usuario: json['usuario']?.toString() ?? '',
      resumen: PerfilResumen.fromJson(json['resumen'] ?? {}),
      leyendo: parseList('leyendo', PerfilLibro.fromJson),
      terminados: parseList('terminados', PerfilLibroTerminado.fromJson),
      abandonados: parseList('abandonados', PerfilLibro.fromJson),
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
  final String libro;
  final String genero;
  final String fecha;
  final String valoracion;
  final String resena;

  PerfilLibroTerminado({
    required this.libro,
    required this.genero,
    required this.fecha,
    required this.valoracion,
    required this.resena,
  });

  factory PerfilLibroTerminado.fromJson(Map<String, dynamic> json) {
    return PerfilLibroTerminado(
      libro: json['libro']?.toString() ?? '',
      genero: json['genero']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      valoracion: json['valoracion']?.toString() ?? '',
      resena: json['resena']?.toString() ?? '',
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
