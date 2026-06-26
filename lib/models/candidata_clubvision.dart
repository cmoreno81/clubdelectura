class CandidataClubvision {
  final String libro;
  final String genero;

  final int interesadas;

  final List<String> usuarias;

  CandidataClubvision({
    required this.libro,
    required this.genero,
    required this.interesadas,
    required this.usuarias,
  });

  factory CandidataClubvision.fromJson(Map<String, dynamic> json) {
    return CandidataClubvision(
      libro: json['libro'] ?? '',

      genero: json['genero'] ?? '',

      interesadas: json['interesadas'] ?? 0,

      usuarias: (json['usuarias'] as List?)?.cast<String>() ?? [],
    );
  }
}
