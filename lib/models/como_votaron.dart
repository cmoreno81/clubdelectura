class ComoVotaron {
  final String usuaria;
  final String avatarUrl;
  final List<VotoEmitido> votos;

  ComoVotaron({
    required this.usuaria,
    required this.avatarUrl,
    required this.votos,
  });

  factory ComoVotaron.fromJson(Map<String, dynamic> json) {
    return ComoVotaron(
      usuaria: json['usuaria']?.toString() ?? '',
      avatarUrl:
          json['avatarUrl']?.toString() ??
          json['fotoUrl']?.toString() ??
          json['photoUrl']?.toString() ??
          '',
      votos: (json['votos'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(VotoEmitido.fromJson)
          .toList(),
    );
  }
}

class VotoEmitido {
  final int puntos;
  final String libro;
  final String bookId;
  final String coverUrl;

  const VotoEmitido({
    required this.puntos,
    required this.libro,
    this.bookId = '',
    this.coverUrl = '',
  });

  factory VotoEmitido.fromJson(Map<String, dynamic> json) {
    return VotoEmitido(
      puntos: (json['puntos'] as num?)?.toInt() ?? 0,
      libro: json['libro']?.toString() ?? '',
      bookId: json['bookId']?.toString() ?? '',
      coverUrl: json['coverUrl']?.toString() ?? '',
    );
  }

  VotoEmitido copyWith({String? bookId, String? coverUrl}) {
    return VotoEmitido(
      puntos: puntos,
      libro: libro,
      bookId: bookId ?? this.bookId,
      coverUrl: coverUrl ?? this.coverUrl,
    );
  }
}
