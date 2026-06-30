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

  ClubvisionData({
    required this.abierta,
    this.estado,
    required this.idVotacion,
    required this.titulo,
    required this.mensaje,
    required this.ganador,
    required this.lectoras,
    required this.candidatas,
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
    );
  }
}
