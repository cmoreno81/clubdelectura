import 'candidata_clubvision.dart';

class ClubvisionData {
  final bool abierta;

  /// Nuevo campo para el motor narrativo.
  /// De momento puede venir nulo porque Apps Script
  /// todavía no lo envía.
  final String? estado;

  final List<CandidataClubvision> candidatas;

  ClubvisionData({
    required this.abierta,
    this.estado,
    required this.candidatas,
  });

  factory ClubvisionData.fromJson(Map<String, dynamic> json) {
    return ClubvisionData(
      abierta: json['abierta'] ?? false,
      estado: json['estado'],
      candidatas:
          (json['candidatas'] as List?)
              ?.map((e) => CandidataClubvision.fromJson(e))
              .toList() ??
          [],
    );
  }
}
