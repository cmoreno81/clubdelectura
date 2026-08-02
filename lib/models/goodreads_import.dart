class GoodreadsImportRow {
  const GoodreadsImportRow({
    required this.title,
    required this.author,
    required this.additionalAuthors,
    required this.isbn,
    required this.isbn13,
    required this.rating,
    required this.pages,
    required this.publicationYear,
    required this.dateRead,
    required this.dateAdded,
    required this.exclusiveShelf,
    required this.review,
  });

  final String title;
  final String author;
  final List<String> additionalAuthors;
  final String isbn;
  final String isbn13;
  final double? rating;
  final int? pages;
  final int? publicationYear;
  final String dateRead;
  final String dateAdded;
  final String exclusiveShelf;
  final String review;

  Map<String, dynamic> toJson() => {
    'title': title,
    'author': author,
    'additionalAuthors': additionalAuthors,
    'isbn': isbn,
    'isbn13': isbn13,
    'rating': rating,
    'pages': pages,
    'publicationYear': publicationYear,
    'dateRead': dateRead,
    'dateAdded': dateAdded,
    'exclusiveShelf': exclusiveShelf,
    'review': review,
  };
}

class GoodreadsImportPreview {
  const GoodreadsImportPreview({required this.summary, required this.books});

  final GoodreadsImportSummary summary;
  final List<GoodreadsImportPreviewBook> books;

  factory GoodreadsImportPreview.fromJson(Map<String, dynamic> json) {
    final summary = json['resumen'];
    return GoodreadsImportPreview(
      summary: GoodreadsImportSummary.fromJson(
        summary is Map<String, dynamic> ? summary : const {},
      ),
      books: (json['libros'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => GoodreadsImportPreviewBook.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
    );
  }
}

class GoodreadsImportSummary {
  const GoodreadsImportSummary({
    required this.total,
    required this.newBooks,
    required this.toAdd,
    required this.protected,
    required this.toReview,
    required this.skipped,
  });

  final int total;
  final int newBooks;
  final int toAdd;
  final int protected;
  final int toReview;
  final int skipped;

  int get imported => newBooks + toAdd;

  factory GoodreadsImportSummary.fromJson(Map<String, dynamic> json) =>
      GoodreadsImportSummary(
        total: (json['total'] as num?)?.toInt() ?? 0,
        newBooks: (json['nuevos'] as num?)?.toInt() ?? 0,
        toAdd:
            (json['paraAnadir'] as num?)?.toInt() ??
            (json['anadidos'] as num?)?.toInt() ??
            0,
        protected: (json['protegidos'] as num?)?.toInt() ?? 0,
        toReview: (json['paraRevisar'] as num?)?.toInt() ?? 0,
        skipped: (json['omitidos'] as num?)?.toInt() ?? 0,
      );
}

class GoodreadsImportPreviewBook {
  const GoodreadsImportPreviewBook({
    required this.index,
    required this.title,
    required this.author,
    required this.action,
    required this.message,
    required this.candidates,
  });

  final int index;
  final String title;
  final String author;
  final String action;
  final String message;
  final List<GoodreadsImportCandidate> candidates;
  bool get canImport => action == 'NUEVO' || action == 'ANADIR';

  factory GoodreadsImportPreviewBook.fromJson(Map<String, dynamic> json) =>
      GoodreadsImportPreviewBook(
        index: (json['index'] as num?)?.toInt() ?? -1,
        title: json['titulo']?.toString() ?? '',
        author: json['autor']?.toString() ?? '',
        action: json['accion']?.toString() ?? 'OMITIR',
        message: json['mensaje']?.toString() ?? '',
        candidates: (json['candidatos'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map(
              (item) => GoodreadsImportCandidate.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false),
      );
}

class GoodreadsImportCandidate {
  const GoodreadsImportCandidate({
    required this.bookId,
    required this.title,
    required this.author,
    required this.isbn,
    required this.coverUrl,
  });

  final String bookId;
  final String title;
  final String author;
  final String isbn;
  final String coverUrl;

  factory GoodreadsImportCandidate.fromJson(Map<String, dynamic> json) =>
      GoodreadsImportCandidate(
        bookId: json['bookId']?.toString() ?? '',
        title: json['titulo']?.toString() ?? '',
        author: json['autor']?.toString() ?? '',
        isbn: json['isbn']?.toString() ?? '',
        coverUrl: json['coverUrl']?.toString() ?? '',
      );
}
