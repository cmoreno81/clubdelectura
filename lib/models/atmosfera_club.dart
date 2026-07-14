class AtmosferaItem {
  final String nombre;
  final String titulo;
  final String descripcion;
  final String icono;
  final double intensidad;

  const AtmosferaItem({
    required this.nombre,
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.intensidad,
  });

  factory AtmosferaItem.fromJson(Map<String, dynamic> json) {
    return AtmosferaItem(
      nombre: json['nombre']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      icono: json['icono']?.toString() ?? '✨',
      intensidad: (json['intensidad'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AtmosferaClub {
  final AtmosferaItem principal;
  final List<AtmosferaItem> secundarias;

  const AtmosferaClub({required this.principal, required this.secundarias});

  factory AtmosferaClub.fromJson(Map<String, dynamic> json) {
    final principalJson =
        json['principal'] as Map<String, dynamic>? ?? const {};

    return AtmosferaClub(
      principal: AtmosferaItem.fromJson(principalJson),
      secundarias: (json['secundarias'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AtmosferaItem.fromJson)
          .toList(),
    );
  }
}
