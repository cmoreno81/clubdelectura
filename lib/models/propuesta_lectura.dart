class ApoyantesPropuesta {
  final String usuario;
  final String avatarUrl;

  const ApoyantesPropuesta({required this.usuario, this.avatarUrl = ''});

  factory ApoyantesPropuesta.fromJson(Map<String, dynamic> json) {
    return ApoyantesPropuesta(
      usuario: json['usuario']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
    );
  }
}

class PropuestaLectura {
  final String id;
  final String bookTitle;
  final String proposedBy;
  final String proposerAvatar;
  final List<ApoyantesPropuesta> apoyos;
  final int totalMiembros;
  final bool yaApoye;
  final bool soyElProponente;

  const PropuestaLectura({
    required this.id,
    required this.bookTitle,
    required this.proposedBy,
    this.proposerAvatar = '',
    this.apoyos = const [],
    required this.totalMiembros,
    this.yaApoye = false,
    this.soyElProponente = false,
  });

  int get apoyosCount => apoyos.length;
  bool get estaCompleta => apoyosCount >= totalMiembros;

  factory PropuestaLectura.fromJson(Map<String, dynamic> json) {
    return PropuestaLectura(
      id: json['id']?.toString() ?? '',
      bookTitle: json['bookTitle']?.toString() ?? '',
      proposedBy: json['proposedBy']?.toString() ?? '',
      proposerAvatar: json['proposerAvatar']?.toString() ?? '',
      apoyos: (json['apoyos'] as List?)
              ?.map((e) => ApoyantesPropuesta.fromJson(e))
              .toList() ??
          [],
      totalMiembros: (json['totalMiembros'] as num?)?.toInt() ?? 1,
      yaApoye: json['yaApoye'] == true,
      soyElProponente: json['soyElProponente'] == true,
    );
  }
}
