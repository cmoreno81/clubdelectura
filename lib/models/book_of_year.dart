class BookOfYearBook {
  const BookOfYearBook({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.authorName,
  });
  final String id;
  final String title;
  final String coverUrl;
  final String authorName;
  factory BookOfYearBook.fromJson(Map<String, dynamic> json) => BookOfYearBook(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    coverUrl: json['coverUrl']?.toString() ?? '',
    authorName: json['authorName']?.toString() ?? '',
  );
}

class BookOfYearMonth {
  const BookOfYearMonth({
    required this.month,
    required this.locked,
    required this.finished,
    required this.eligible,
    this.selection,
  });
  final int month;
  final bool locked;
  final bool finished;
  final List<BookOfYearBook> eligible;
  final BookOfYearBook? selection;
  factory BookOfYearMonth.fromJson(Map<String, dynamic> json) =>
      BookOfYearMonth(
        month: (json['month'] as num?)?.toInt() ?? 0,
        locked: json['locked'] == true,
        finished: json['finished'] == true,
        eligible: (json['eligible'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) =>
                  BookOfYearBook.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(),
        selection: json['selection'] is Map
            ? BookOfYearBook.fromJson(
                Map<String, dynamic>.from(json['selection'] as Map),
              )
            : null,
      );
}

class BookOfYearDuel {
  const BookOfYearDuel({
    required this.phase,
    required this.position,
    required this.automatic,
    required this.unlocked,
    required this.candidates,
    this.winner,
  });
  final String phase;
  final int position;
  final bool automatic;
  final bool unlocked;
  final List<BookOfYearBook> candidates;
  final BookOfYearBook? winner;
  factory BookOfYearDuel.fromJson(Map<String, dynamic> json) => BookOfYearDuel(
    phase: json['phase']?.toString() ?? '',
    position: (json['position'] as num?)?.toInt() ?? 0,
    automatic: json['automatic'] == true,
    unlocked: json['unlocked'] == true,
    candidates: (json['candidates'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => BookOfYearBook.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
    winner: json['winner'] is Map
        ? BookOfYearBook.fromJson(
            Map<String, dynamic>.from(json['winner'] as Map),
          )
        : null,
  );
}

class BookOfYearBoard {
  const BookOfYearBoard({
    required this.year,
    required this.editable,
    required this.userName,
    required this.avatarUrl,
    required this.hasSelections,
    required this.months,
    required this.duels,
    required this.finalists,
    this.winner,
  });
  final int year;
  final bool editable;
  final String userName;
  final String avatarUrl;
  final bool hasSelections;
  final List<BookOfYearMonth> months;
  final List<BookOfYearDuel> duels;
  final List<BookOfYearBook> finalists;
  final BookOfYearBook? winner;
  factory BookOfYearBoard.fromJson(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(json['usuario'] as Map? ?? const {});
    return BookOfYearBoard(
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      editable: json['editable'] == true,
      userName: user['nombre']?.toString() ?? '',
      avatarUrl: user['avatarUrl']?.toString() ?? '',
      hasSelections: json['hasSelections'] == true,
      months: (json['months'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => BookOfYearMonth.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      duels: (json['duels'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => BookOfYearDuel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      finalists: (json['finalists'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => BookOfYearBook.fromJson(
              Map<String, dynamic>.from((item['book'] as Map?) ?? item),
            ),
          )
          .toList(),
      winner: json['winner'] is Map
          ? BookOfYearBook.fromJson(
              Map<String, dynamic>.from(json['winner'] as Map),
            )
          : null,
    );
  }
}

class ClubBookOfYearMember {
  const ClubBookOfYearMember({
    required this.userName,
    required this.avatarUrl,
    required this.completedMonths,
    required this.selections,
    required this.finalists,
    this.winner,
  });
  final String userName;
  final String avatarUrl;
  final int completedMonths;
  final List<BookOfYearBook> selections;
  final List<BookOfYearBook> finalists;
  final BookOfYearBook? winner;
  factory ClubBookOfYearMember.fromJson(Map<String, dynamic> json) =>
      ClubBookOfYearMember(
        userName: json['usuario']?.toString() ?? '',
        avatarUrl: json['avatarUrl']?.toString() ?? '',
        completedMonths: (json['completedMonths'] as num?)?.toInt() ?? 0,
        selections: (json['selections'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) => BookOfYearBook.fromJson(
                Map<String, dynamic>.from((item['book'] as Map?) ?? item),
              ),
            )
            .toList(),
        finalists: (json['finalists'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) =>
                  BookOfYearBook.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(),
        winner: json['winner'] is Map
            ? BookOfYearBook.fromJson(
                Map<String, dynamic>.from(json['winner'] as Map),
              )
            : null,
      );
}
