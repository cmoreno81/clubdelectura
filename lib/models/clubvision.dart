import 'candidata_clubvision.dart';

class ClubvisionData {
  final bool abierta;

  final String? estado;

  final String idVotacion;

  final String titulo;

  final String mensaje;

  final String ganador;

  final List<String> lectoras;

  final List<CandidataClubvision> candidatas;

  final bool haVotado;

  final int votosRecibidos;

  final int totalUsuarios;

  final int votosPendientes;

  final int porcentaje;

  ClubvisionData({
    required this.abierta,
    this.estado,
    required this.idVotacion,
    required this.titulo,
    required this.mensaje,
    required this.ganador,
    required this.lectoras,
    required this.candidatas,
    required this.haVotado,
    required this.votosRecibidos,
    required this.totalUsuarios,
    required this.votosPendientes,
    required this.porcentaje,
  });

  factory ClubvisionData.fromJson(Map<String, dynamic> json) {
    return ClubvisionData(
      abierta: json['abierta'] ?? false,
      estado: json['estado'],

      idVotacion: json['idVotacion'] ?? '',

      titulo: json['titulo'] ?? '',

      mensaje: json['mensaje'] ?? '',

      ganador: json['ganador'] ?? '',

      lectoras: List<String>.from(json['lectoras'] ?? []),

      candidatas:
          (json['candidatas'] as List?)
              ?.map((e) => CandidataClubvision.fromJson(e))
              .toList() ??
          [],
      haVotado: json['haVotado'] ?? false,
      votosRecibidos: (json['votosRecibidos'] as num?)?.toInt() ?? 0,

      totalUsuarios: (json['totalUsuarios'] as num?)?.toInt() ?? 0,

      votosPendientes: (json['votosPendientes'] as num?)?.toInt() ?? 0,

      porcentaje: (json['porcentaje'] as num?)?.toInt() ?? 0,
    );
  }
}
