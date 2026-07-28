class GeneralDashboard {
  const GeneralDashboard({
    required this.userName,
    required this.avatarUrl,
    required this.summary,
    required this.clubs,
    required this.currentBooks,
    required this.calendar,
    required this.trending,
    required this.community,
  });

  final String userName;
  final String avatarUrl;
  final GeneralSummary summary;
  final List<GeneralClub> clubs;
  final List<GeneralBook> currentBooks;
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
    required this.pagesRead,
    required this.monthStreak,
  });

  final int clubs;
  final int reading;
  final int finished;
  final int finishedThisMonth;
  final int pagesRead;
  final int monthStreak;

  factory GeneralSummary.fromJson(Map<String, dynamic> json) => GeneralSummary(
    clubs: _integer(json['clubes']),
    reading: _integer(json['leyendo']),
    finished: _integer(json['terminados']),
    finishedThisMonth: _integer(json['terminadosMes']),
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
  });

  final int year;
  final int month;
  final List<ReadingCalendarEvent> events;

  factory ReadingCalendar.fromJson(Map<String, dynamic> json) =>
      ReadingCalendar(
        year: _integer(json['anio']),
        month: _integer(json['mes']),
        events: _list(json['eventos'], ReadingCalendarEvent.fromJson),
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
  });

  final int clubs;
  final int readers;
  final int activeReadings;

  factory CommunitySummary.fromJson(Map<String, dynamic> json) =>
      CommunitySummary(
        clubs: _integer(json['clubes']),
        readers: _integer(json['lectoras']),
        activeReadings: _integer(json['lecturasActivas']),
      );
}

int _integer(dynamic value) => (value as num?)?.toInt() ?? 0;
int? _nullableInteger(dynamic value) => (value as num?)?.toInt();
