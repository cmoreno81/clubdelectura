class MiVoto {
  final bool encontrado;

  final List<String> votos;

  final int votosRecibidos;
  final int totalUsuarios;
  final int votosPendientes;
  final int porcentaje;

  MiVoto({
    required this.encontrado,
    required this.votos,
    required this.votosRecibidos,
    required this.totalUsuarios,
    required this.votosPendientes,
    required this.porcentaje,
  });

  factory MiVoto.fromJson(Map<String, dynamic> json) {
    return MiVoto(
      encontrado: json["encontrado"] ?? false,
      votos: List<String>.from(json["votos"] ?? []),
      votosRecibidos: json["votosRecibidos"] ?? 0,
      totalUsuarios: json["totalUsuarios"] ?? 0,
      votosPendientes: json["votosPendientes"] ?? 0,
      porcentaje: json["porcentaje"] ?? 0,
    );
  }
}
