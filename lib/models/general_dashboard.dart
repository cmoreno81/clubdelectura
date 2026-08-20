class GeneralDashboard {
  const GeneralDashboard({
    required this.userName,
    this.userId = '',
    required this.avatarUrl,
    required this.summary,
    required this.clubs,
    required this.currentBooks,
    required this.personalLibrary,
    required this.latestAdditions,
    required this.clubvisionNotice,
    required this.openSeries,
    this._yearShelf,
    required this.calendar,
    required this.trending,
    this.trendingAuthors = const [],
    required this.community,
  });

  final String userName;
  final String userId;
  final String avatarUrl;
  final GeneralSummary summary;
  final List<GeneralClub> clubs;
  final List<GeneralBook> currentBooks;
  final List<PersonalLibraryBook> personalLibrary;
  final List<GeneralLatestBook> latestAdditions;
  final GeneralClubvisionNotice? clubvisionNotice;
  final List<GeneralOpenSeries> openSeries;
  final List<YearShelfBook>? _yearShelf;
  List<YearShelfBook> get yearShelf => _yearShelf ?? const [];
  final ReadingCalendar calendar;
  final List<TrendingBook> trending;
  final List<TrendingAuthor> trendingAuthors;
  final CommunitySummary community;

  int get pagesReadThisMonth {
    if (summary.pagesReadThisMonth > 0) return summary.pagesReadThisMonth;
    return calendar.finishedBooks.fold(0, (total, book) => total + book.pages);
  }

  factory GeneralDashboard.fromJson(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(json['usuario'] as Map? ?? {});
    final personalLibrary = _list(
      json['miBiblioteca'],
      PersonalLibraryBook.fromJson,
    );
    final latestAdditions = _reconcileLatestAdditions(
      _list(json['ultimasIncorporaciones'], GeneralLatestBook.fromJson),
      personalLibrary,
    );
    return GeneralDashboard(
      userName: user['nombre']?.toString() ?? '',
      userId: user['id']?.toString() ?? user['userId']?.toString() ?? '',
      avatarUrl: user['avatarUrl']?.toString() ?? '',
      summary: GeneralSummary.fromJson(
        Map<String, dynamic>.from(json['resumen'] as Map? ?? {}),
      ),
      clubs: _list(json['clubes'], GeneralClub.fromJson),
      currentBooks: _list(json['leyendoAhora'], GeneralBook.fromJson),
      personalLibrary: personalLibrary,
      latestAdditions: latestAdditions,
      clubvisionNotice: json['clubvisionAviso'] is Map
          ? GeneralClubvisionNotice.fromJson(
              Map<String, dynamic>.from(json['clubvisionAviso'] as Map),
            )
          : null,
      openSeries: _list(json['sagasAbiertas'], GeneralOpenSeries.fromJson),
      yearShelf: _list(json['estanteriaAnual'], YearShelfBook.fromJson),
      calendar: ReadingCalendar.fromJson(
        Map<String, dynamic>.from(json['calendario'] as Map? ?? {}),
      ),
      trending: _list(json['tendencias'], TrendingBook.fromJson),
      trendingAuthors: _list(json['autoresTendencia'], TrendingAuthor.fromJson),
      community: CommunitySummary.fromJson(
        Map<String, dynamic>.from(json['comunidad'] as Map? ?? {}),
      ),
    );
  }
}

List<GeneralLatestBook> _reconcileLatestAdditions(
  List<GeneralLatestBook> latest,
  List<PersonalLibraryBook> library,
) {
  final libraryById = <String, PersonalLibraryBook>{};
  final libraryByTitle = <String, PersonalLibraryBook>{};
  for (final book in library) {
    if (book.id.trim().isNotEmpty && book.coverUrl.trim().isNotEmpty) {
      libraryById[book.id.trim()] = book;
    }
    if (book.coverUrl.trim().isNotEmpty) {
      libraryByTitle[_normalizedTitle(book.title)] = book;
    }
  }

  final reconciled = <String, GeneralLatestBook>{};
  for (final book in latest) {
    final normalizedTitle = _normalizedTitle(book.title);
    final key = normalizedTitle.isNotEmpty
        ? 'title:$normalizedTitle'
        : 'id:${book.id.trim()}';
    final libraryBook =
        libraryById[book.id.trim()] ??
        libraryByTitle[_normalizedTitle(book.title)];
    final candidate = book.coverUrl.trim().isNotEmpty || libraryBook == null
        ? book
        : book.withCover(libraryBook.coverUrl);
    final previous = reconciled[key];
    if (previous == null ||
        (previous.coverUrl.trim().isEmpty &&
            candidate.coverUrl.trim().isNotEmpty)) {
      reconciled[key] = candidate;
    }
  }
  return reconciled.values.toList(growable: false);
}

String _normalizedTitle(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[áàäâ]'), 'a')
    .replaceAll(RegExp(r'[éèëê]'), 'e')
    .replaceAll(RegExp(r'[íìïî]'), 'i')
    .replaceAll(RegExp(r'[óòöô]'), 'o')
    .replaceAll(RegExp(r'[úùüû]'), 'u')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();

class GeneralClubvisionNotice {
  const GeneralClubvisionNotice({
    required this.type,
    required this.edition,
    required this.readyClubs,
    required this.clubs,
  });

  final String type;
  final String edition;
  final int readyClubs;
  final List<GeneralClubvisionNoticeClub> clubs;

  String get message {
    final clubName = clubs.length == 1 ? clubs.first.name : '';
    final destination = clubName.isNotEmpty
        ? ' en $clubName'
        : readyClubs > 1
        ? ' en $readyClubs clubes'
        : '';
    switch (type) {
      case 'APERTURA':
        return 'Esta noche abre una nueva edición de Clubvisión$destination';
      case 'VOTACION':
        return 'Clubvisión está abierto$destination: ya puedes votar';
      case 'GALA':
        return 'Hoy llega la gala de Clubvisión$destination';
      default:
        return '';
    }
  }

  factory GeneralClubvisionNotice.fromJson(Map<String, dynamic> json) =>
      GeneralClubvisionNotice(
        type: json['tipo']?.toString() ?? '',
        edition: json['edicion']?.toString() ?? '',
        readyClubs: _integer(json['clubesPreparados']),
        clubs: _list(json['clubes'], GeneralClubvisionNoticeClub.fromJson),
      );
}

class GeneralClubvisionNoticeClub {
  const GeneralClubvisionNoticeClub({
    required this.id,
    required this.name,
    required this.candidates,
  });

  final String id;
  final String name;
  final int candidates;

  factory GeneralClubvisionNoticeClub.fromJson(Map<String, dynamic> json) =>
      GeneralClubvisionNoticeClub(
        id: json['id']?.toString() ?? '',
        name: json['nombre']?.toString() ?? '',
        candidates: _integer(json['candidatas']),
      );
}

class GeneralLatestBook {
  const GeneralLatestBook({
    required this.id,
    required this.title,
    required this.author,
    required this.genre,
    required this.coverUrl,
    required this.addedAt,
  });

  final String id;
  final String title;
  final String author;
  final String genre;
  final String coverUrl;
  final String addedAt;

  GeneralLatestBook withCover(String value) => GeneralLatestBook(
    id: id,
    title: title,
    author: author,
    genre: genre,
    coverUrl: value,
    addedAt: addedAt,
  );

  factory GeneralLatestBook.fromJson(Map<String, dynamic> json) =>
      GeneralLatestBook(
        id: json['id']?.toString() ?? '',
        title: json['titulo']?.toString() ?? '',
        author: json['autor']?.toString() ?? '',
        genre: json['genero']?.toString() ?? '',
        coverUrl: json['coverUrl']?.toString() ?? '',
        addedAt: json['fechaAlta']?.toString() ?? '',
      );
}

class YearShelfBook {
  const YearShelfBook({
    required this.id,
    required this.bookId,
    required this.title,
    required this.coverUrl,
    required this.finishedAt,
  });

  final String id;
  final String bookId;
  final String title;
  final String coverUrl;
  final String finishedAt;

  factory YearShelfBook.fromJson(Map<String, dynamic> json) => YearShelfBook(
    id: json['id']?.toString() ?? '',
    bookId: json['bookId']?.toString() ?? '',
    title: json['titulo']?.toString() ?? '',
    coverUrl: json['coverUrl']?.toString() ?? '',
    finishedAt: json['fechaFin']?.toString() ?? '',
  );
}

class PersonalLibraryBook {
  const PersonalLibraryBook({
    required this.id,
    required this.title,
    required this.genre,
    required this.coverUrl,
    required this.priority,
    required this.status,
    required this.format,
  });

  final String id;
  final String title;
  final String genre;
  final String coverUrl;
  final String priority;
  final String status;
  final String format;

  bool get isHighPriority => priority == 'ALTA';

  factory PersonalLibraryBook.fromJson(Map<String, dynamic> json) =>
      PersonalLibraryBook(
        id: json['id']?.toString() ?? '',
        title: json['titulo']?.toString() ?? '',
        genre: json['genero']?.toString() ?? '',
        coverUrl: json['coverUrl']?.toString() ?? '',
        priority: json['prioridad']?.toString() ?? 'MEDIA',
        status: json['estado']?.toString() ?? 'PENDIENTE',
        format: json['formato']?.toString() ?? '',
      );
}

class GeneralOpenSeries {
  const GeneralOpenSeries({
    required this.id,
    required this.name,
    required this.read,
    required this.total,
    this.status = 'EN_CURSO',
    this.coverUrl = '',
    this.next,
  });

  final String id;
  final String name;
  final int read;
  final int total;
  final String status;
  final String coverUrl;
  final GeneralSeriesNextBook? next;

  double get progress => total <= 0 ? 0 : read / total;

  factory GeneralOpenSeries.fromJson(Map<String, dynamic> json) {
    final next = json['siguiente'];
    return GeneralOpenSeries(
      id: json['id']?.toString() ?? '',
      name: json['nombre']?.toString() ?? '',
      read: _integer(json['leidos']),
      total: _integer(json['total']),
      status: json['estado']?.toString() ?? 'EN_CURSO',
      coverUrl: json['coverUrl']?.toString() ?? '',
      next: next is Map
          ? GeneralSeriesNextBook.fromJson(Map<String, dynamic>.from(next))
          : null,
    );
  }
}

class GeneralSeriesNextBook {
  const GeneralSeriesNextBook({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.inMyLibrary,
  });

  final String id;
  final String title;
  final String coverUrl;
  final bool inMyLibrary;

  factory GeneralSeriesNextBook.fromJson(Map<String, dynamic> json) =>
      GeneralSeriesNextBook(
        id: json['id']?.toString() ?? '',
        title: json['titulo']?.toString() ?? '',
        coverUrl: json['coverUrl']?.toString() ?? '',
        inMyLibrary: json['enMiBiblioteca'] == true,
      );
}

List<T> _list<T>(dynamic value, T Function(Map<String, dynamic>) parser) =>
    (value as List<dynamic>? ?? const [])
        .map((item) => parser(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);

class GeneralSummary {
  const GeneralSummary({
    required this.clubs,
    required this.reading,
    required this.finished,
    required this.finishedThisMonth,
    required this.pagesReadThisMonth,
    required this.pagesRead,
    required this.monthStreak,
  });

  final int clubs;
  final int reading;
  final int finished;
  final int finishedThisMonth;
  final int pagesReadThisMonth;
  final int pagesRead;
  final int monthStreak;

  factory GeneralSummary.fromJson(Map<String, dynamic> json) => GeneralSummary(
    clubs: _integer(json['clubes']),
    reading: _integer(json['leyendo']),
    finished: _integer(json['terminados']),
    finishedThisMonth: _integer(json['terminadosMes']),
    pagesReadThisMonth: _integer(json['paginasMes']),
    pagesRead: _integer(json['paginasLeidas']),
    monthStreak: _integer(json['rachaMeses']),
  );
}

class GeneralClub {
  const GeneralClub({
    required this.id,
    required this.name,
    required this.role,
    required this.active,
    required this.members,
    required this.activeReadings,
    this.description = '',
    this.avatarUrl = '',
    this.tipo = 'SOCIAL',
  });

  final String id;
  final String name;
  final String description;
  final String avatarUrl;
  final String role;
  final bool active;
  final int members;
  final int activeReadings;

  /// 'SOCIAL' o 'PERSONAL'
  final String tipo;

  bool get esPersonal => tipo == 'PERSONAL';

  factory GeneralClub.fromJson(Map<String, dynamic> json) => GeneralClub(
    id: json['id']?.toString() ?? '',
    name: json['nombre']?.toString() ?? '',
    description: json['descripcion']?.toString() ?? '',
    avatarUrl: json['avatarUrl']?.toString() ?? '',
    role: json['rol']?.toString() ?? 'MEMBER',
    active: json['activo'] == true,
    members: _integer(json['miembros']),
    activeReadings: _integer(json['lecturasActivas']),
    tipo: json['tipo']?.toString() ?? 'SOCIAL',
  );
}

class GeneralBook {
  const GeneralBook({
    required this.id,
    required this.title,
    required this.genre,
    required this.coverUrl,
    required this.progress,
    this.currentPage,
    this.pages,
  });

  final String id;
  final String title;
  final String genre;
  final String coverUrl;
  final int progress;
  final int? currentPage;
  final int? pages;

  factory GeneralBook.fromJson(Map<String, dynamic> json) => GeneralBook(
    id: json['id']?.toString() ?? '',
    title: json['titulo']?.toString() ?? '',
    genre: json['genero']?.toString() ?? '',
    coverUrl: json['coverUrl']?.toString() ?? '',
    progress: _integer(json['progreso']),
    currentPage: _nullableInteger(json['paginaActual']),
    pages: _nullableInteger(json['paginas']),
  );
}

class ReadingCalendar {
  const ReadingCalendar({
    required this.year,
    required this.month,
    required this.events,
    this.finishedBooks = const [],
    this.readings = const [],
  });

  final int year;
  final int month;
  final List<ReadingCalendarEvent> events;
  final List<MonthlyFinishedBook> finishedBooks;
  final List<MonthlyReadingSpan> readings;

  factory ReadingCalendar.fromJson(
    Map<String, dynamic> json,
  ) => ReadingCalendar(
    year: _integer(json['anio']),
    month: _integer(json['mes']),
    events: _list(json['eventos'], ReadingCalendarEvent.fromJson),
    finishedBooks: _list(json['librosLeidos'], MonthlyFinishedBook.fromJson),
    readings: _list(json['lecturasCalendario'], MonthlyReadingSpan.fromJson),
  );
}

class MonthlyReadingSpan {
  const MonthlyReadingSpan({
    required this.id,
    required this.libraryId,
    required this.bookId,
    required this.title,
    required this.coverUrl,
    required this.startedAt,
    required this.finishedAt,
  });

  /// Formato: `completion:<id>` o `library:<id>`
  final String id;

  /// Library.id — siempre presente (necesario para actualizarFechasLectura).
  final String libraryId;

  final String bookId;
  final String title;
  final String coverUrl;
  final String startedAt;
  final String finishedAt;

  bool get isCompleted => id.startsWith('completion:');
  String get completionId =>
      isCompleted ? id.replaceFirst('completion:', '') : '';

  factory MonthlyReadingSpan.fromJson(Map<String, dynamic> json) =>
      MonthlyReadingSpan(
        id: json['id']?.toString() ?? '',
        libraryId: json['libraryId']?.toString() ?? '',
        bookId: json['bookId']?.toString() ?? '',
        title: json['titulo']?.toString() ?? '',
        coverUrl: json['coverUrl']?.toString() ?? '',
        startedAt: json['fechaInicio']?.toString() ?? '',
        finishedAt: json['fechaFin']?.toString() ?? '',
      );
}

class MonthlyFinishedBook {
  const MonthlyFinishedBook({
    required this.id,
    required this.bookId,
    required this.title,
    required this.coverUrl,
    required this.finishedAt,
    required this.pages,
    this.rating,
  });

  final String id;
  final String bookId;
  final String title;
  final String coverUrl;
  final String finishedAt;
  final int pages;

  /// Valoración del usuario (0.5–5.0), null si no ha valorado aún.
  final double? rating;

  factory MonthlyFinishedBook.fromJson(Map<String, dynamic> json) =>
      MonthlyFinishedBook(
        id: json['id']?.toString() ?? '',
        bookId: json['bookId']?.toString() ?? '',
        title: json['titulo']?.toString() ?? '',
        coverUrl: json['coverUrl']?.toString() ?? '',
        finishedAt: json['fechaFin']?.toString() ?? '',
        pages: _integer(json['paginas']),
        rating: json['valoracion'] != null
            ? (json['valoracion'] as num).toDouble()
            : null,
      );
}

class ReadingCalendarEvent {
  const ReadingCalendarEvent({
    required this.date,
    required this.day,
    required this.types,
    required this.books,
  });

  final String date;
  final int day;
  final List<String> types;
  final List<String> books;

  factory ReadingCalendarEvent.fromJson(Map<String, dynamic> json) =>
      ReadingCalendarEvent(
        date: json['fecha']?.toString() ?? '',
        day: _integer(json['dia']),
        types: (json['tipos'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(growable: false),
        books: (json['libros'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(growable: false),
      );
}

class TrendingAuthor {
  const TrendingAuthor({
    required this.id,
    required this.nombre,
    required this.photoUrl,
    required this.libros,
  });

  final String id;
  final String nombre;
  final String photoUrl;
  final int libros;

  factory TrendingAuthor.fromJson(Map<String, dynamic> json) => TrendingAuthor(
    id: json['id']?.toString() ?? '',
    nombre: json['nombre']?.toString() ?? '',
    photoUrl: json['photoUrl']?.toString() ?? '',
    libros: _integer(json['libros']),
  );
}

class TrendingBook {
  const TrendingBook({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.readers,
  });

  final String id;
  final String title;
  final String coverUrl;
  final int readers;

  factory TrendingBook.fromJson(Map<String, dynamic> json) => TrendingBook(
    id: json['id']?.toString() ?? '',
    title: json['titulo']?.toString() ?? '',
    coverUrl: json['coverUrl']?.toString() ?? '',
    readers: _integer(json['lectoras']),
  );
}

class CommunitySummary {
  const CommunitySummary({
    required this.clubs,
    required this.readers,
    required this.activeReadings,
    required this.formats,
  });

  final int clubs;
  final int readers;
  final int activeReadings;
  final CommunityReadingFormats formats;

  factory CommunitySummary.fromJson(Map<String, dynamic> json) =>
      CommunitySummary(
        clubs: _integer(json['clubes']),
        readers: _integer(json['lectoras']),
        activeReadings: _integer(json['lecturasActivas']),
        formats: CommunityReadingFormats.fromJson(
          Map<String, dynamic>.from(json['formatos'] as Map? ?? {}),
        ),
      );
}

class CommunityReadingFormats {
  const CommunityReadingFormats({
    required this.physical,
    required this.digital,
    required this.audiobook,
    required this.total,
  });

  final int physical;
  final int digital;
  final int audiobook;
  final int total;

  factory CommunityReadingFormats.fromJson(Map<String, dynamic> json) =>
      CommunityReadingFormats(
        physical: _integer(json['fisico']),
        digital: _integer(json['digital']),
        audiobook: _integer(json['audiolibro']),
        total: _integer(json['total']),
      );
}

int _integer(dynamic value) => (value as num?)?.toInt() ?? 0;
int? _nullableInteger(dynamic value) => (value as num?)?.toInt();
