class HistorialClubvision {
  final String mes;

  final String ganadora;

  final int puntos;

  final String segunda;

  final String tercera;
  final String ganadoraBookId;
  final String ganadoraCoverUrl;
  final String segundaBookId;
  final String segundaCoverUrl;
  final String terceraBookId;
  final String terceraCoverUrl;

  const HistorialClubvision({
    required this.mes,
    required this.ganadora,
    required this.puntos,
    required this.segunda,
    required this.tercera,
    this.ganadoraBookId = '',
    this.ganadoraCoverUrl = '',
    this.segundaBookId = '',
    this.segundaCoverUrl = '',
    this.terceraBookId = '',
    this.terceraCoverUrl = '',
  });

  factory HistorialClubvision.fromJson(Map<String, dynamic> json) {
    return HistorialClubvision(
      mes: json["mes"] ?? "",

      ganadora: json["ganadora"] ?? "",

      puntos: json["puntos"] ?? 0,
      segunda: json["segunda"] ?? "",
      tercera: json["tercera"] ?? "",
      ganadoraBookId: json['ganadoraBookId']?.toString() ?? '',
      ganadoraCoverUrl: json['ganadoraCoverUrl']?.toString() ?? '',
      segundaBookId: json['segundaBookId']?.toString() ?? '',
      segundaCoverUrl: json['segundaCoverUrl']?.toString() ?? '',
      terceraBookId: json['terceraBookId']?.toString() ?? '',
      terceraCoverUrl: json['terceraCoverUrl']?.toString() ?? '',
    );
  }

  HistorialClubvision copyWith({
    String? ganadoraBookId,
    String? ganadoraCoverUrl,
    String? segundaBookId,
    String? segundaCoverUrl,
    String? terceraBookId,
    String? terceraCoverUrl,
  }) {
    return HistorialClubvision(
      mes: mes,
      ganadora: ganadora,
      puntos: puntos,
      segunda: segunda,
      tercera: tercera,
      ganadoraBookId: ganadoraBookId ?? this.ganadoraBookId,
      ganadoraCoverUrl: ganadoraCoverUrl ?? this.ganadoraCoverUrl,
      segundaBookId: segundaBookId ?? this.segundaBookId,
      segundaCoverUrl: segundaCoverUrl ?? this.segundaCoverUrl,
      terceraBookId: terceraBookId ?? this.terceraBookId,
      terceraCoverUrl: terceraCoverUrl ?? this.terceraCoverUrl,
    );
  }
}
