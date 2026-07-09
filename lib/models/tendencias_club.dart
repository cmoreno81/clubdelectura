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
  final String nombre;
  final int total;

  TendenciaItem({required this.nombre, required this.total});

  factory TendenciaItem.fromJson(Map<String, dynamic> json) {
    return TendenciaItem(
      nombre: json['nombre']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}
