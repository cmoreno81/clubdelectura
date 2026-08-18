class CursorPage<T> {
  const CursorPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
    this.cutoffDate,
  });

  final List<T> items;
  final String? nextCursor;
  final bool hasMore;

  /// Corte de novedad ISO devuelto por el backend en la primera página.
  /// Indica el instante de la última visita anterior del usuario.
  /// Los comentarios con `fecha > cutoffDate` son nuevos.
  final String? cutoffDate;

  factory CursorPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return CursorPage<T>(
      items: rawItems
          .whereType<Map>()
          .map((item) => fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      nextCursor: json['nextCursor']?.toString(),
      hasMore: json['hasMore'] == true,
      cutoffDate: json['cutoffDate']?.toString(),
    );
  }
}
