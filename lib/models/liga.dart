// Modelos de las Ligas de ClubReads (ranking individual por temporadas).

class LigaTemporada {
  final int numero;
  final DateTime terminaEn;
  final int totalParticipantes;

  const LigaTemporada({
    required this.numero,
    required this.terminaEn,
    required this.totalParticipantes,
  });

  factory LigaTemporada.fromJson(Map<String, dynamic> json) => LigaTemporada(
    numero: (json['numero'] as num?)?.toInt() ?? 0,
    terminaEn:
        DateTime.tryParse(json['terminaEn']?.toString() ?? '')?.toLocal() ??
        DateTime.now(),
    totalParticipantes: (json['totalParticipantes'] as num?)?.toInt() ?? 0,
  );
}

class LigaFila {
  final int puesto;
  final String userId;
  final String nombre;
  final String? avatarUrl;
  final int puntos;
  final bool esTu;

  const LigaFila({
    required this.puesto,
    required this.userId,
    required this.nombre,
    required this.avatarUrl,
    required this.puntos,
    required this.esTu,
  });

  factory LigaFila.fromJson(Map<String, dynamic> json) => LigaFila(
    puesto: (json['puesto'] as num?)?.toInt() ?? 0,
    userId: json['userId']?.toString() ?? '',
    nombre: json['nombre']?.toString() ?? '',
    avatarUrl: (json['avatarUrl']?.toString().trim().isEmpty ?? true)
        ? null
        : json['avatarUrl'].toString(),
    puntos: (json['puntos'] as num?)?.toInt() ?? 0,
    esTu: json['esTu'] == true,
  );
}

class LigaHistorico {
  final int temporadasJugadas;
  final int? mejorPuesto;
  final int? mejorPuntuacion;
  final int podios;

  const LigaHistorico({
    required this.temporadasJugadas,
    required this.mejorPuesto,
    required this.mejorPuntuacion,
    required this.podios,
  });

  factory LigaHistorico.fromJson(Map<String, dynamic>? json) => LigaHistorico(
    temporadasJugadas: (json?['temporadasJugadas'] as num?)?.toInt() ?? 0,
    mejorPuesto: (json?['mejorPuesto'] as num?)?.toInt(),
    mejorPuntuacion: (json?['mejorPuntuacion'] as num?)?.toInt(),
    podios: (json?['podios'] as num?)?.toInt() ?? 0,
  );
}

class LigaEstado {
  final bool participando;
  final LigaTemporada temporada;
  final int miPuesto;
  final int misPuntos;
  final List<LigaFila> tabla;
  final LigaHistorico historico;

  const LigaEstado({
    required this.participando,
    required this.temporada,
    required this.miPuesto,
    required this.misPuntos,
    required this.tabla,
    required this.historico,
  });

  factory LigaEstado.fromJson(Map<String, dynamic> json) => LigaEstado(
    participando: json['participando'] == true,
    temporada: LigaTemporada.fromJson(
      (json['temporada'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    miPuesto: (json['miPuesto'] as num?)?.toInt() ?? 0,
    misPuntos: (json['misPuntos'] as num?)?.toInt() ?? 0,
    tabla: ((json['tabla'] as List?) ?? const [])
        .map((e) => LigaFila.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    historico: LigaHistorico.fromJson(
      (json['historico'] as Map?)?.cast<String, dynamic>(),
    ),
  );
}
