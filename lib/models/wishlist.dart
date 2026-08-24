class WishlistItem {
  const WishlistItem({
    required this.id,
    this.bookId,
    required this.title,
    this.author,
    this.coverUrl,
    this.isbn,
    required this.format,
    required this.priority,
    this.price,
    this.releaseDate,
    this.plannedMonth,
    this.purchasedAt,
    this.note,
    required this.isUpcoming,
    required this.isInLibrary,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? bookId;
  final String title;
  final String? author;
  final String? coverUrl;
  final String? isbn;
  final WishlistFormat format;
  final WishlistPriority priority;
  final double? price;
  final DateTime? releaseDate;
  final DateTime? plannedMonth;
  final DateTime? purchasedAt;
  final String? note;
  final bool isUpcoming;
  final bool isInLibrary;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isFree => price == 0;

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] as String,
      bookId: json['bookId'] as String?,
      title: json['title'] as String,
      author: json['author'] as String?,
      coverUrl: json['coverUrl'] as String?,
      isbn: json['isbn'] as String?,
      format: WishlistFormat.fromString(
        json['format'] as String? ?? 'PHYSICAL',
      ),
      priority: WishlistPriority.fromString(
        json['priority'] as String? ?? 'MEDIUM',
      ),
      price: (json['price'] as num?)?.toDouble(),
      releaseDate: json['releaseDate'] != null
          ? DateTime.tryParse(json['releaseDate'] as String)
          : null,
      plannedMonth: json['plannedMonth'] != null
          ? DateTime.tryParse(json['plannedMonth'] as String)
          : null,
      purchasedAt: json['purchasedAt'] != null
          ? DateTime.tryParse(json['purchasedAt'] as String)
          : null,
      note: json['note'] as String?,
      isUpcoming: json['isUpcoming'] as bool? ?? false,
      isInLibrary: json['isInLibrary'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  WishlistItem copyWith({
    String? title,
    String? author,
    String? coverUrl,
    String? isbn,
    WishlistFormat? format,
    WishlistPriority? priority,
    double? price,
    DateTime? releaseDate,
    bool clearReleaseDate = false,
    DateTime? plannedMonth,
    bool clearPlannedMonth = false,
    String? note,
  }) {
    return WishlistItem(
      id: id,
      bookId: bookId,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      isbn: isbn ?? this.isbn,
      format: format ?? this.format,
      priority: priority ?? this.priority,
      price: price ?? this.price,
      releaseDate: clearReleaseDate ? null : (releaseDate ?? this.releaseDate),
      plannedMonth: clearPlannedMonth
          ? null
          : (plannedMonth ?? this.plannedMonth),
      note: note ?? this.note,
      isUpcoming: clearReleaseDate
          ? false
          : (releaseDate != null
                ? releaseDate.isAfter(DateTime.now())
                : isUpcoming),
      isInLibrary: isInLibrary,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// ── Enums ──────────────────────────────────────────────────────────────────────

enum WishlistFormat {
  physical,
  digital,
  audiobook;

  static WishlistFormat fromString(String value) => switch (value) {
    'PHYSICAL' => WishlistFormat.physical,
    'DIGITAL' => WishlistFormat.digital,
    'AUDIOBOOK' => WishlistFormat.audiobook,
    _ => WishlistFormat.physical,
  };

  String toApiValue() => switch (this) {
    WishlistFormat.physical => 'PHYSICAL',
    WishlistFormat.digital => 'DIGITAL',
    WishlistFormat.audiobook => 'AUDIOBOOK',
  };

  String get label => switch (this) {
    WishlistFormat.physical => 'Físico',
    WishlistFormat.digital => 'Digital',
    WishlistFormat.audiobook => 'Audio',
  };

  String get emoji => switch (this) {
    WishlistFormat.physical => '📕',
    WishlistFormat.digital => '📱',
    WishlistFormat.audiobook => '🎧',
  };
}

enum WishlistPriority {
  high,
  medium,
  low;

  static WishlistPriority fromString(String value) => switch (value) {
    'HIGH' => WishlistPriority.high,
    'MEDIUM' => WishlistPriority.medium,
    'LOW' => WishlistPriority.low,
    _ => WishlistPriority.medium,
  };

  String toApiValue() => switch (this) {
    WishlistPriority.high => 'HIGH',
    WishlistPriority.medium => 'MEDIUM',
    WishlistPriority.low => 'LOW',
  };

  String get label => switch (this) {
    WishlistPriority.high => 'Alta',
    WishlistPriority.medium => 'Media',
    WishlistPriority.low => 'Baja',
  };

  String get emoji => switch (this) {
    WishlistPriority.high => '🔴',
    WishlistPriority.medium => '🟠',
    WishlistPriority.low => '🟢',
  };
}

// ── Respuesta de la API ────────────────────────────────────────────────────────

class WishlistSummary {
  const WishlistSummary({
    required this.totalItems,
    required this.totalPrice,
    required this.upcomingCount,
    required this.availableCount,
    required this.physicalCount,
    required this.digitalCount,
    required this.audiobookCount,
    required this.thisMonthPrice,
  });

  final int totalItems;
  final double totalPrice;
  final int upcomingCount;
  final int availableCount;
  final int physicalCount;
  final int digitalCount;
  final int audiobookCount;
  final double thisMonthPrice;

  factory WishlistSummary.fromJson(Map<String, dynamic> json) {
    return WishlistSummary(
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      upcomingCount: (json['upcomingCount'] as num?)?.toInt() ?? 0,
      availableCount: (json['availableCount'] as num?)?.toInt() ?? 0,
      physicalCount: (json['physicalCount'] as num?)?.toInt() ?? 0,
      digitalCount: (json['digitalCount'] as num?)?.toInt() ?? 0,
      audiobookCount: (json['audiobookCount'] as num?)?.toInt() ?? 0,
      thisMonthPrice: (json['thisMonthPrice'] as num?)?.toDouble() ?? 0,
    );
  }

  static const empty = WishlistSummary(
    totalItems: 0,
    totalPrice: 0,
    upcomingCount: 0,
    availableCount: 0,
    physicalCount: 0,
    digitalCount: 0,
    audiobookCount: 0,
    thisMonthPrice: 0,
  );
}

class WishlistData {
  const WishlistData({
    required this.items,
    required this.upcoming,
    required this.available,
    required this.purchased,
    required this.totalItems,
    required this.totalPrice,
    required this.summary,
  });

  final List<WishlistItem> items;
  final List<WishlistItem> upcoming;
  final List<WishlistItem> available;
  final List<WishlistItem> purchased;
  final int totalItems;
  final double totalPrice;
  final WishlistSummary summary;

  factory WishlistData.fromJson(Map<String, dynamic> json) {
    List<WishlistItem> parseList(dynamic raw) => (raw as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(WishlistItem.fromJson)
        .toList(growable: false);

    return WishlistData(
      items: parseList(json['items']),
      upcoming: parseList(json['upcoming']),
      available: parseList(json['available']),
      purchased: parseList(json['purchased']),
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      summary: json['summary'] != null
          ? WishlistSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : WishlistSummary.empty,
    );
  }

  static const empty = WishlistData(
    items: [],
    upcoming: [],
    available: [],
    purchased: [],
    totalItems: 0,
    totalPrice: 0,
    summary: WishlistSummary.empty,
  );
}

// ── Club wishlist ─────────────────────────────────────────────────────────────

class ClubWishlistMember {
  const ClubWishlistMember({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.price,
    this.note,
    required this.format,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
  final double? price;
  final String? note;
  final WishlistFormat format;

  factory ClubWishlistMember.fromJson(Map<String, dynamic> json) {
    return ClubWishlistMember(
      userId: json['userId'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      note: _nonEmptyString(json['note'] ?? json['nota'] ?? json['comentario']),
      format: WishlistFormat.fromString(
        json['format'] as String? ?? 'PHYSICAL',
      ),
    );
  }
}

String? _nonEmptyString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

class ClubWishlistGroup {
  const ClubWishlistGroup({
    required this.key,
    this.bookId,
    required this.title,
    this.author,
    this.coverUrl,
    this.releaseDate,
    required this.isUpcoming,
    required this.isInMyWishlist,
    required this.members,
  });

  final String key;
  final String? bookId;
  final String title;
  final String? author;
  final String? coverUrl;
  final DateTime? releaseDate;
  final bool isUpcoming;
  final bool isInMyWishlist;
  final List<ClubWishlistMember> members;

  factory ClubWishlistGroup.fromJson(Map<String, dynamic> json) {
    return ClubWishlistGroup(
      key: json['key'] as String,
      bookId: json['bookId'] as String?,
      title: json['title'] as String,
      author: json['author'] as String?,
      coverUrl: json['coverUrl'] as String?,
      releaseDate: json['releaseDate'] != null
          ? DateTime.tryParse(json['releaseDate'] as String)
          : null,
      isUpcoming: json['isUpcoming'] as bool? ?? false,
      isInMyWishlist: json['isInMyWishlist'] as bool? ?? false,
      members: (json['members'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ClubWishlistMember.fromJson)
          .toList(growable: false),
    );
  }
}

class ClubWishlistData {
  const ClubWishlistData({
    required this.clubName,
    required this.items,
    required this.totalItems,
    required this.totalMembers,
    required this.membersWithWishlist,
  });

  final String clubName;
  final List<ClubWishlistGroup> items;
  final int totalItems;
  final int totalMembers;
  final int membersWithWishlist;

  factory ClubWishlistData.fromJson(Map<String, dynamic> json) {
    return ClubWishlistData(
      clubName: json['clubName'] as String,
      items: (json['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ClubWishlistGroup.fromJson)
          .toList(growable: false),
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalMembers: (json['totalMembers'] as num?)?.toInt() ?? 0,
      membersWithWishlist: (json['membersWithWishlist'] as num?)?.toInt() ?? 0,
    );
  }
}
