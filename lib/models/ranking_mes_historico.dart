class RankingLectoraMes {
  final String nombre;
  final String avatarUrl;
  final int total;

  const RankingLectoraMes({
    required this.nombre,
    this.avatarUrl = '',
    required this.total,
  });

  factory RankingLectoraMes.fromJson(Map<String, dynamic> json) {
    return RankingLectoraMes(
      nombre: json['usuario']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class RankingMesHistorico {
  /// 0 = enero … 11 = diciembre
  final int mes;
  final List<RankingLectoraMes> top;

  const RankingMesHistorico({required this.mes, required this.top});

  factory RankingMesHistorico.fromJson(Map<String, dynamic> json) {
    return RankingMesHistorico(
      mes: (json['mes'] as num?)?.toInt() ?? 0,
      top: (json['top'] as List?)
              ?.map((e) => RankingLectoraMes.fromJson(e))
              .toList() ??
          [],
    );
  }

  String get nombreMes {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return meses[mes.clamp(0, 11)];
  }
}
