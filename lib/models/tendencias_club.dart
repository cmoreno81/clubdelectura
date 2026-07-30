// lib/models/tendencias_club.dart

class TendenciasClub {
  final String titular;
  final String narrador;
  final List<TendenciaItem> generos;
  final List<TendenciaItem> libros;
  final List<TendenciaItem> lectoras;
  final int totalLeyendo;

  TendenciasClub({
    required this.titular,
    required this.narrador,
    required this.generos,
    required this.libros,
    required this.lectoras,
    required this.totalLeyendo,
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
