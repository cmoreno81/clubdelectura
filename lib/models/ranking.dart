import 'ranking_item.dart';

class Ranking {
  final List<RankingItem> masDeseados;

  final List<RankingItem> masLeidos;

  final List<RankingItem> mejorValorados;

  final List<RankingItem> masAbandonados;

  final List<RankingItem> topLectoras;

  Ranking({
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
      masDeseados: parse('masDeseados'),

      masLeidos: parse('masLeidos'),

      mejorValorados: parse('mejorValorados'),

      masAbandonados: parse('masAbandonados'),

      topLectoras: parse('topLectoras'),
    );
  }
}
