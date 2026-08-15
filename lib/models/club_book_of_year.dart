class ClubBookOfYearCandidate {
  const ClubBookOfYearCandidate({
    required this.id,
    required this.bookId,
    required this.title,
    required this.coverUrl,
    required this.authorName,
    this.source = 'OFFICIAL_READING',
    this.clubvisionEdition,
    this.needsReview = false,
  });
  final String id;
  final String bookId;
  final String title;
  final String coverUrl;
  final String authorName;
  final String source;
  final String? clubvisionEdition;
  final bool needsReview;
  factory ClubBookOfYearCandidate.fromJson(Map<String, dynamic> json) =>
      ClubBookOfYearCandidate(
        id: json['candidateId']?.toString() ?? json['id']?.toString() ?? '',
        bookId: json['bookId']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        coverUrl: json['coverUrl']?.toString() ?? '',
        authorName: json['authorName']?.toString() ?? '',
        source: json['source']?.toString() ?? 'OFFICIAL_READING',
        clubvisionEdition: json['clubvisionEdition']?.toString(),
        needsReview: json['needsReview'] == true,
      );
}

class ClubBookOfYearDuel {
  const ClubBookOfYearDuel({
    required this.id,
    required this.position,
    required this.a,
    required this.b,
    this.winner,
    this.myVoteCandidateId,
    this.tied = false,
  });
  final String id;
  final int position;
  final ClubBookOfYearCandidate a;
  final ClubBookOfYearCandidate b;
  final ClubBookOfYearCandidate? winner;
  final String? myVoteCandidateId;
  final bool tied;
  factory ClubBookOfYearDuel.fromJson(Map<String, dynamic> json) =>
      ClubBookOfYearDuel(
        id: json['id']?.toString() ?? '',
        position: (json['position'] as num?)?.toInt() ?? 0,
        a: ClubBookOfYearCandidate.fromJson(
          Map<String, dynamic>.from(json['candidateA'] as Map),
        ),
        b: ClubBookOfYearCandidate.fromJson(
          Map<String, dynamic>.from(json['candidateB'] as Map),
        ),
        winner: json['winner'] is Map
            ? ClubBookOfYearCandidate.fromJson(
                Map<String, dynamic>.from(json['winner'] as Map),
              )
            : null,
        myVoteCandidateId: json['myVoteCandidateId']?.toString(),
        tied: json['tied'] == true,
      );
}

class ClubBookOfYearRound {
  const ClubBookOfYearRound({
    required this.id,
    required this.phase,
    required this.status,
    required this.duels,
  });
  final String id;
  final String phase;
  final String status;
  final List<ClubBookOfYearDuel> duels;
  factory ClubBookOfYearRound.fromJson(Map<String, dynamic> json) =>
      ClubBookOfYearRound(
        id: json['id']?.toString() ?? '',
        phase: json['phase']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        duels: (json['duels'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) =>
                  ClubBookOfYearDuel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(),
      );
}

class ClubBookOfYearEdition {
  const ClubBookOfYearEdition({
    required this.clubName,
    required this.year,
    required this.status,
    required this.canAdmin,
    required this.candidates,
    required this.myQualifyingVotes,
    required this.rounds,
    this.winner,
    this.candidatesSyncedAt,
  });
  final String clubName;
  final int year;
  final String status;
  final bool canAdmin;
  final List<ClubBookOfYearCandidate> candidates;
  final List<String> myQualifyingVotes;
  final List<ClubBookOfYearRound> rounds;
  final ClubBookOfYearCandidate? winner;
  final DateTime? candidatesSyncedAt;
  factory ClubBookOfYearEdition.fromJson(
    Map<String, dynamic> json,
  ) => ClubBookOfYearEdition(
    clubName: json['clubName']?.toString() ?? '',
    year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
    status: json['status']?.toString() ?? 'NOT_STARTED',
    canAdmin: json['canAdmin'] == true,
    candidates: (json['candidates'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              ClubBookOfYearCandidate.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(),
    myQualifyingVotes: (json['myQualifyingVotes'] as List? ?? const [])
        .map((item) => item.toString())
        .toList(),
    rounds: (json['rounds'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              ClubBookOfYearRound.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(),
    winner: json['winner'] is Map
        ? ClubBookOfYearCandidate.fromJson(
            Map<String, dynamic>.from(json['winner'] as Map),
          )
        : null,
    candidatesSyncedAt: DateTime.tryParse(
      json['candidatesSyncedAt']?.toString() ?? '',
    ),
  );
}
