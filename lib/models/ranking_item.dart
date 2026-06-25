class RankingItem {

  final String nombre;

  final int total;

  final double media;

  final int votos;

  RankingItem({

    required this.nombre,

    this.total = 0,

    this.media = 0,

    this.votos = 0,
  });

  factory RankingItem.fromJson(
    Map<String, dynamic> json,
  ) {

    return RankingItem(

      nombre:

          json['libro'] ??

          json['usuario'] ??

          '',

      total:
          json['total'] ?? 0,

      media:
          (json['media'] ?? 0)
              .toDouble(),

      votos:
          json['votos'] ?? 0,
    );
  }
}