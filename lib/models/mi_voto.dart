class VotoItem {
  const VotoItem({required this.titulo, required this.coverUrl});
  final String titulo;
  final String coverUrl;
  factory VotoItem.fromJson(Map<String, dynamic> json) => VotoItem(
    titulo: json['titulo']?.toString() ?? '',
    coverUrl: json['coverUrl']?.toString() ?? '',
  );
}

class MiVoto {
  final bool encontrado;

  final List<VotoItem> votos;

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
      votos: (json["votos"] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(VotoItem.fromJson)
          .toList(growable: false),
      votosRecibidos: json["votosRecibidos"] ?? 0,
      totalUsuarios: json["totalUsuarios"] ?? 0,
      votosPendientes: json["votosPendientes"] ?? 0,
      porcentaje: json["porcentaje"] ?? 0,
    );
  }
}
