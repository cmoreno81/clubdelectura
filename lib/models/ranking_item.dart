class RankingItem {
  final String nombre;
  final String avatarUrl;
  final int total;
  final double media;
  final int votos;

  const RankingItem({
    required this.nombre,
    this.avatarUrl = '',
    this.total = 0,
    this.media = 0,
    this.votos = 0,
  });

  factory RankingItem.fromJson(Map<String, dynamic> json) {
    return RankingItem(
      nombre: json['libro']?.toString() ?? json['usuario']?.toString() ?? '',

      avatarUrl: json['avatarUrl']?.toString() ?? '',

      total: (json['total'] as num?)?.toInt() ?? 0,

      media: (json['media'] as num?)?.toDouble() ?? 0,

      votos: (json['votos'] as num?)?.toInt() ?? 0,
    );
  }
}
