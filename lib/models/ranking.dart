import 'ranking_item.dart';

class Ranking {
  final int anio;
  final List<RankingItem> masDeseados;

  final List<RankingItem> masLeidos;

  final List<RankingItem> mejorValorados;

  final List<RankingItem> masAbandonados;

  final List<RankingItem> topLectoras;

  Ranking({
    required this.anio,
    required this.masDeseados,

    required this.masLeidos,

    required this.mejorValorados,

    required this.masAbandonados,

    required this.topLectoras,
  });

  factory Ranking.fromJson(Map<String, dynamic> json) {
    List<RankingItem> parse(String key) {
      return (json[key] as List?)
              ?.map((e) => RankingItem.fromJson(e))
              .toList() ??
          [];
    }

    return Ranking(
      anio: (json['anio'] as num?)?.toInt() ?? DateTime.now().year,
      masDeseados: parse('masDeseados'),

      masLeidos: parse('masLeidos'),

      mejorValorados: parse('mejorValorados'),

      masAbandonados: parse('masAbandonados'),

      topLectoras: parse('topLectoras'),
    );
  }
}
