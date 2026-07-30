class GeneralDashboard {
  const GeneralDashboard({
    required this.userName,
    required this.avatarUrl,
    required this.summary,
    required this.clubs,
    required this.currentBooks,
    required this.personalLibrary,
    required this.openSeries,
    this._yearShelf,
    required this.calendar,
    required this.trending,
    required this.community,
  });

  final String userName;
  final String avatarUrl;
  final GeneralSummary summary;
  final List<GeneralClub> clubs;
  final List<GeneralBook> currentBooks;
  final List<PersonalLibraryBook> personalLibrary;
  final List<GeneralOpenSeries> openSeries;
  final List<YearShelfBook>? _yearShelf;
  List<YearShelfBook> get yearShelf => _yearShelf ?? const [];
  final ReadingCalendar calendar;
  final List<TrendingBook> trending;
  final CommunitySummary community;

  factory GeneralDashboard.fromJson(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(json['usuario'] as Map? ?? {});
    return GeneralDashboard(
      userName: user['nombre']?.toString() ?? '',
      avatarUrl: user['avatarUrl']?.toString() ?? '',
      summary: GeneralSummary.fromJson(
        Map<String, dynamic>.from(json['resumen'] as Map? ?? {}),
      ),
      clubs: _list(json['clubes'], GeneralClub.fromJson),
      currentBooks: _list(json['leyendoAhora'], GeneralBook.fromJson),
      personalLibrary: _list(
        json['miBiblioteca'],
        PersonalLibraryBook.fromJson,
      ),
      openSeries: _list(json['sagasAbiertas'], GeneralOpenSeries.fromJson),
      yearShelf: _list(json['estanteriaAnual'], YearShelfBook.fromJson),
      calendar: ReadingCalendar.fromJson(
        Map<String, dynamic>.from(json['calendario'] as Map? ?? {}),
      ),
      trending: _list(json['tendencias'], TrendingBook.fromJson),
      community: CommunitySummary.fromJson(
        Map<String, dynamic>.from(json['comunidad'] as Map? ?? {}),
      ),
    );
  }
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
    this.coverUrl = '',
    this.next,
  });

  final String id;
  final String name;
  final int read;
  final int total;
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
  });

  final String id;
  final String name;
  final String description;
  final String avatarUrl;
  final String role;
  final bool active;
  final int members;
  final int activeReadings;

  factory GeneralClub.fromJson(Map<String, dynamic> json) => GeneralClub(
    id: json['id']?.toString() ?? '',
    name: json['nombre']?.toString() ?? '',
    description: json['descripcion']?.toString() ?? '',
    avatarUrl: json['avatarUrl']?.toString() ?? '',
    role: json['rol']?.toString() ?? 'MEMBER',
    active: json['activo'] == true,
    members: _integer(json['miembros']),
    activeReadings: _integer(json['lecturasActivas']),
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
    required this.bookId,
    required this.title,
    required this.coverUrl,
    required this.startedAt,
    required this.finishedAt,
  });

  final String id;
  final String bookId;
  final String title;
  final String coverUrl;
  final String startedAt;
  final String finishedAt;

  factory MonthlyReadingSpan.fromJson(Map<String, dynamic> json) =>
      MonthlyReadingSpan(
        id: json['id']?.toString() ?? '',
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
  });

  final String id;
  final String bookId;
  final String title;
  final String coverUrl;
  final String finishedAt;
  final int pages;

  factory MonthlyFinishedBook.fromJson(Map<String, dynamic> json) =>
      MonthlyFinishedBook(
        id: json['id']?.toString() ?? '',
        bookId: json['bookId']?.toString() ?? '',
        title: json['titulo']?.toString() ?? '',
        coverUrl: json['coverUrl']?.toString() ?? '',
        finishedAt: json['fechaFin']?.toString() ?? '',
        pages: _integer(json['paginas']),
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
