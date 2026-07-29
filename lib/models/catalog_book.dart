class CatalogBook {
  const CatalogBook({
    required this.id,
    required this.source,
    required this.title,
    required this.authors,
    required this.coverUrl,
    required this.genre,
    required this.isbn,
    required this.inMyLibrary,
    required this.status,
    this.pages,
    this.publicationYear,
  });

  final String id;
  final String source;
  final String title;
  final List<String> authors;
  final String coverUrl;
  final String genre;
  final String isbn;
  final bool inMyLibrary;
  final String status;
  final int? pages;
  final int? publicationYear;

  String get authorLabel =>
      authors.isEmpty ? 'Autor desconocido' : authors.join(', ');
  bool get isExternal => source != 'CLUBREADS';

  String get sourceLabel => switch (source) {
    'GOOGLE' => 'Google Books',
    'OPENLIBRARY' => 'Open Library',
    _ => 'En ClubReads',
  };

  factory CatalogBook.fromJson(Map<String, dynamic> json) => CatalogBook(
    id: json['id']?.toString() ?? '',
    source: json['origen']?.toString() ?? 'CLUBREADS',
    title: json['titulo']?.toString() ?? '',
    authors: (json['autores'] as List<dynamic>? ?? const [])
        .map((author) => author.toString())
        .where((author) => author.trim().isNotEmpty)
        .toList(growable: false),
    coverUrl: json['coverUrl']?.toString() ?? '',
    genre: json['genero']?.toString() ?? '',
    isbn: json['isbn']?.toString() ?? '',
    inMyLibrary: json['enMiBiblioteca'] == true,
    status: json['estado']?.toString() ?? '',
    pages: _intOrNull(json['paginas']),
    publicationYear: _intOrNull(json['anioPublicacion']),
  );

  CatalogBook copyWith({bool? inMyLibrary, String? status}) => CatalogBook(
    id: id,
    source: source,
    title: title,
    authors: authors,
    coverUrl: coverUrl,
    genre: genre,
    isbn: isbn,
    inMyLibrary: inMyLibrary ?? this.inMyLibrary,
    status: status ?? this.status,
    pages: pages,
    publicationYear: publicationYear,
  );
}

int? _intOrNull(dynamic value) {
  if (value == null) return null;
  return int.tryParse(value.toString());
}
