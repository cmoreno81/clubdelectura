// lib/models/tendencias_club.dart

class TendenciasClub {
  final String titular;
  final String narrador;
  final List<TendenciaItem> generos;
  final List<TendenciaItem> libros;
  final List<TendenciaItem> lectoras;
  final int totalLeyendo;
  final ComparativaClub? comparativa;

  TendenciasClub({
    required this.titular,
    required this.narrador,
    required this.generos,
    required this.libros,
    required this.lectoras,
    required this.totalLeyendo,
    this.comparativa,
  });

  factory TendenciasClub.fromJson(Map<String, dynamic> json) {
    List<TendenciaItem> parse(String key) {
      return (json[key] as List? ?? [])
          .map((e) => TendenciaItem.fromJson(e))
          .toList();
    }

    return TendenciasClub(
      titular: json['titular']?.toString() ?? '',
      narrador: json['narrador']?.toString() ?? '',
      generos: parse('generos'),
      libros: parse('libros'),
      lectoras: parse('lectoras'),
      totalLeyendo: (json['totalLeyendo'] as num?)?.toInt() ?? 0,
      comparativa: json['comparativa'] is Map
          ? ComparativaClub.fromJson(
              Map<String, dynamic>.from(json['comparativa'] as Map),
            )
          : null,
    );
  }
}

// ── Comparativa: tu club frente a toda la comunidad ──────────────────────────

class ComparativaClub {
  final ComparativaCategoria generos;
  final ComparativaCategoria idiomas;
  final ComparativaCategoria formatos;

  ComparativaClub({
    required this.generos,
    required this.idiomas,
    required this.formatos,
  });

  factory ComparativaClub.fromJson(Map<String, dynamic> json) {
    ComparativaCategoria parse(String key) => ComparativaCategoria.fromJson(
      Map<String, dynamic>.from(json[key] as Map? ?? {}),
    );
    return ComparativaClub(
      generos: parse('generos'),
      idiomas: parse('idiomas'),
      formatos: parse('formatos'),
    );
  }
}

class ComparativaCategoria {
  final List<ComparativaItem> items;
  final int totalClub;
  final int totalComunidad;

  ComparativaCategoria({
    required this.items,
    required this.totalClub,
    required this.totalComunidad,
  });

  factory ComparativaCategoria.fromJson(Map<String, dynamic> json) {
    return ComparativaCategoria(
      items: (json['items'] as List? ?? [])
          .map((e) => ComparativaItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      totalClub: (json['totalClub'] as num?)?.toInt() ?? 0,
      totalComunidad: (json['totalComunidad'] as num?)?.toInt() ?? 0,
    );
  }
}

class ComparativaItem {
  final String nombre;
  final int club;
  final double porcentajeClub;
  final double porcentajeComunidad;

  ComparativaItem({
    required this.nombre,
    required this.club,
    required this.porcentajeClub,
    required this.porcentajeComunidad,
  });

  factory ComparativaItem.fromJson(Map<String, dynamic> json) {
    return ComparativaItem(
      nombre: json['nombre']?.toString() ?? '',
      club: (json['club'] as num?)?.toInt() ?? 0,
      porcentajeClub: (json['porcentajeClub'] as num?)?.toDouble() ?? 0,
      porcentajeComunidad:
          (json['porcentajeComunidad'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TendenciaItem {
  final String id;
  final String nombre;
  final int total;
  final String coverUrl;
  final String avatarUrl;

  TendenciaItem({
    this.id = '',
    required this.nombre,
    required this.total,
    this.coverUrl = '',
    this.avatarUrl = '',
  });

  factory TendenciaItem.fromJson(Map<String, dynamic> json) {
    return TendenciaItem(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
      coverUrl: json['coverUrl']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
    );
  }
}
