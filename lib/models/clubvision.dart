import 'candidata_clubvision.dart';

class ClubvisionData {
  final bool abierta;

  final List<CandidataClubvision> candidatas;

  ClubvisionData({required this.abierta, required this.candidatas});

  factory ClubvisionData.fromJson(Map<String, dynamic> json) {
    return ClubvisionData(
      abierta: json['abierta'] ?? false,

      candidatas:
          (json['candidatas'] as List?)
              ?.map((e) => CandidataClubvision.fromJson(e))
              .toList() ??
          [],
    );
  }
}
