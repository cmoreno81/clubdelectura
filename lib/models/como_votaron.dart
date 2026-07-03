class ComoVotaron {
  final String usuaria;
  final List<VotoEmitido> votos;

  ComoVotaron({required this.usuaria, required this.votos});

  factory ComoVotaron.fromJson(Map<String, dynamic> json) {
    return ComoVotaron(
      usuaria: json["usuaria"] ?? "",
      votos: (json["votos"] as List<dynamic>? ?? [])
          .map((e) => VotoEmitido.fromJson(e))
          .toList(),
    );
  }
}

class VotoEmitido {
  final int puntos;
  final String libro;

  VotoEmitido({required this.puntos, required this.libro});

  factory VotoEmitido.fromJson(Map<String, dynamic> json) {
    return VotoEmitido(puntos: json["puntos"] ?? 0, libro: json["libro"] ?? "");
  }
}
