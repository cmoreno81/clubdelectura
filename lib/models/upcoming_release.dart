class UpcomingRelease {
  const UpcomingRelease({
    required this.id,
    required this.title,
    required this.publicationDate,
    required this.genre,
    required this.isInWishlist,
    required this.isInLibrary,
    this.author,
    this.isbn,
    this.coverUrl,
    this.publisher,
    this.source,
    this.sourceUrl,
    this.wishlistItemId,
    this.cliches = const [],
  });

  final String id;
  final String title;
  final String? author;
  final String? isbn;
  final String? coverUrl;
  final DateTime publicationDate;
  final String genre;
  final String? publisher;
  final String? source;
  final String? sourceUrl;
  final bool isInWishlist;
  final String? wishlistItemId;
  final bool isInLibrary;
  final List<String> cliches;

  factory UpcomingRelease.fromJson(
    Map<String, dynamic> json,
  ) => UpcomingRelease(
    id: json['bookId']?.toString() ?? json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? json['titulo']?.toString() ?? '',
    author: json['author']?.toString() ?? json['autor']?.toString(),
    isbn: json['isbn']?.toString(),
    coverUrl: json['coverUrl']?.toString(),
    publicationDate: DateTime.parse(
      (json['publicationDate'] ??
              json['fechaPublicacion'] ??
              json['fechaLanzamiento'])
          .toString(),
    ),
    genre: json['genre']?.toString() ?? json['genero']?.toString() ?? '',
    publisher: json['publisher']?.toString() ?? json['editorial']?.toString(),
    source: json['source']?.toString() ?? json['fuente']?.toString(),
    sourceUrl: json['sourceUrl']?.toString() ?? json['urlFuente']?.toString(),
    isInWishlist: json['isInWishlist'] == true || json['enWishlist'] == true,
    wishlistItemId: json['wishlistItemId']?.toString(),
    isInLibrary: json['isInLibrary'] == true || json['enBiblioteca'] == true,
    cliches: (json['cliches'] as List<dynamic>? ?? const [])
        .map((value) => value.toString())
        .where((value) => value.isNotEmpty)
        .toList(growable: false),
  );

  UpcomingRelease copyWith({
    bool? isInWishlist,
    String? wishlistItemId,
    bool clearWishlistItemId = false,
    bool? isInLibrary,
  }) => UpcomingRelease(
    id: id,
    title: title,
    author: author,
    isbn: isbn,
    coverUrl: coverUrl,
    publicationDate: publicationDate,
    genre: genre,
    publisher: publisher,
    source: source,
    sourceUrl: sourceUrl,
    isInWishlist: isInWishlist ?? this.isInWishlist,
    wishlistItemId: clearWishlistItemId
        ? null
        : (wishlistItemId ?? this.wishlistItemId),
    isInLibrary: isInLibrary ?? this.isInLibrary,
    cliches: cliches,
  );
}
