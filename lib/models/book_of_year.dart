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
    id: json['bookId']?.toString() ?? json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? json['titulo']?.toString() ?? '',
    coverUrl: json['coverUrl']?.toString() ?? '',
    authorName:
        json['authorName']?.toString() ?? json['autor']?.toString() ?? '',
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
    this.userId = '',
    required this.userName,
    required this.avatarUrl,
    required this.completedMonths,
    required this.selections,
    required this.finalists,
    this.previewBooks = const [],
    this.pendingDuels = 0,
    this.winner,
  });
  final String userName;
  final String userId;
  final String avatarUrl;
  final int completedMonths;
  final List<BookOfYearBook> selections;
  final List<BookOfYearBook> finalists;
  final List<ClubBookOfYearPreviewBook> previewBooks;
  final int pendingDuels;
  final BookOfYearBook? winner;
  factory ClubBookOfYearMember.fromJson(Map<String, dynamic> json) {
    final rawDuels = (json['duels'] as List? ?? const []).whereType<Map>();
    final explicitPreview =
        (json['previewBooks'] as List? ??
                json['advancedBooks'] as List? ??
                const [])
            .whereType<Map>()
            .map(
              (item) => ClubBookOfYearPreviewBook.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
    final duelPreview = rawDuels.expand((raw) {
      final duel = Map<String, dynamic>.from(raw);
      final phase = duel['phase']?.toString() ?? '';
      final position = (duel['position'] as num?)?.toInt() ?? 0;
      final winner = duel['winner'];
      if (winner is Map) {
        return [
          ClubBookOfYearPreviewBook(
            status: 'CHOSEN',
            phase: phase,
            position: position,
            book: BookOfYearBook.fromJson(Map<String, dynamic>.from(winner)),
            manual: duel['automatic'] != true,
            valid: duel['valid'] != false && duel['invalidated'] != true,
          ),
        ];
      }
      return (duel['candidates'] as List? ?? const []).whereType<Map>().map(
        (candidate) => ClubBookOfYearPreviewBook(
          status: 'PENDING',
          phase: phase,
          position: position,
          book: BookOfYearBook.fromJson(Map<String, dynamic>.from(candidate)),
        ),
      );
    }).toList();
    final pendingFromDuels = rawDuels
        .where((raw) => raw['winner'] == null)
        .length;
    return ClubBookOfYearMember(
      userId: json['userId']?.toString() ?? '',
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
            (item) => BookOfYearBook.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      previewBooks: [...explicitPreview, ...duelPreview],
      pendingDuels: (json['pendingDuels'] as num?)?.toInt() ?? pendingFromDuels,
      winner: json['winner'] is Map
          ? BookOfYearBook.fromJson(
              Map<String, dynamic>.from(json['winner'] as Map),
            )
          : null,
    );
  }

  List<ClubBookOfYearPreviewBook> get previewSlots {
    if (winner != null) {
      return [ClubBookOfYearPreviewBook.chosen(winner!, phase: 'WINNER')];
    }
    if (finalists.isNotEmpty) {
      return finalists
          .take(2)
          .map((book) => ClubBookOfYearPreviewBook.chosen(book, phase: 'FINAL'))
          .toList(growable: false);
    }
    if (previewBooks.isNotEmpty) {
      final ordered =
          previewBooks
              .where(
                (item) =>
                    item.valid &&
                    item.manual &&
                    item.status == 'CHOSEN' &&
                    item.book != null,
              )
              .toList()
            ..sort((a, b) {
              final phase = b.phaseRank.compareTo(a.phaseRank);
              return phase != 0 ? phase : a.position.compareTo(b.position);
            });
      final result = <ClubBookOfYearPreviewBook>[];
      final ids = <String>{};
      final highestRank = ordered.isEmpty ? null : ordered.first.phaseRank;
      for (final item in ordered) {
        if (item.phaseRank != highestRank) break;
        if (!ids.add(item.book!.id)) continue;
        result.add(item);
        if (result.length == 2) break;
      }
      if (result.length == 1 &&
          pendingDuels > 0 &&
          result.first.status == 'CHOSEN') {
        result.add(const ClubBookOfYearPreviewBook.pending());
      }
      if (result.isNotEmpty) return result;
    }
    final ids = <String>{};
    final monthly = selections
        .where((book) => ids.add(book.id))
        .take(2)
        .map((book) => ClubBookOfYearPreviewBook.chosen(book, phase: 'MONTH'))
        .toList(growable: false);
    if (monthly.isNotEmpty) return monthly;
    return previewBooks
        .where(
          (item) => item.valid && item.status == 'PENDING' && item.book != null,
        )
        .where((item) => ids.add(item.book!.id))
        .take(2)
        .toList(growable: false);
  }
}

class ClubBookOfYearPreviewBook {
  const ClubBookOfYearPreviewBook({
    required this.status,
    required this.phase,
    required this.position,
    this.book,
    this.manual = true,
    this.valid = true,
  });

  const ClubBookOfYearPreviewBook.pending({this.phase = '', this.position = 0})
    : status = 'PENDING',
      book = null,
      manual = true,
      valid = true;

  factory ClubBookOfYearPreviewBook.chosen(
    BookOfYearBook book, {
    required String phase,
    int position = 0,
  }) => ClubBookOfYearPreviewBook(
    status: 'CHOSEN',
    phase: phase,
    position: position,
    book: book,
  );

  final String status;
  final String phase;
  final int position;
  final BookOfYearBook? book;
  final bool manual;
  final bool valid;

  int get phaseRank => switch (phase.toUpperCase()) {
    'WINNER' || 'ANNUAL' => 5,
    'FINAL' => 4,
    'SEMIFINAL' => 3,
    'QUARTERFINAL' || 'QUARTER_FINAL' => 2,
    'MONTH_PAIR' || 'FIRST_ROUND' => 1,
    _ => 0,
  };

  factory ClubBookOfYearPreviewBook.fromJson(Map<String, dynamic> json) {
    final rawBook = json['book'];
    final status = json['status']?.toString().toUpperCase() ?? 'CHOSEN';
    final bookData = rawBook is Map ? rawBook : json;
    final parsedBook = BookOfYearBook.fromJson(
      Map<String, dynamic>.from(bookData),
    );
    final book = parsedBook.id.isEmpty && parsedBook.title.isEmpty
        ? null
        : parsedBook;
    return ClubBookOfYearPreviewBook(
      status: status,
      phase: json['phase']?.toString() ?? '',
      position: (json['position'] as num?)?.toInt() ?? 0,
      book: book,
      manual: json['automatic'] != true,
      valid: json['valid'] != false && json['invalidated'] != true,
    );
  }
}
