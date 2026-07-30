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
    required this.title,
    required this.author,
    required this.action,
    required this.message,
  });

  final String title;
  final String author;
  final String action;
  final String message;

  factory GoodreadsImportPreviewBook.fromJson(Map<String, dynamic> json) =>
      GoodreadsImportPreviewBook(
        title: json['titulo']?.toString() ?? '',
        author: json['autor']?.toString() ?? '',
        action: json['accion']?.toString() ?? 'OMITIR',
        message: json['mensaje']?.toString() ?? '',
      );
}
