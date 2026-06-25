class HistorialClubvision {

  final String mes;

  final String ganadora;

  final int puntos;

  final String segunda;

  final String tercera;

  HistorialClubvision({

    required this.mes,

    required this.ganadora,

    required this.puntos,

    required this.segunda,

    required this.tercera,
  });

  factory HistorialClubvision.fromJson(
    Map<String, dynamic> json,
  ) {

    return HistorialClubvision(

      mes: json["mes"] ?? "",

      ganadora:
          json["ganadora"] ?? "",

      puntos:
          json["puntos"] ?? 0,

      segunda:
          json["segunda"] ?? "",

      tercera:
          json["tercera"] ?? "",
    );
  }
}