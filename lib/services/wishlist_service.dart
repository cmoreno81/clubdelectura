import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/wishlist.dart';
import '../utils/app_config.dart';
import 'api_exception.dart';
import 'authenticated_http_client.dart';
import 'http_response_handler.dart';

class WishlistService {
  WishlistService({http.Client? client})
      : _client = client ?? AuthenticatedHttpClient();

  final http.Client _client;

  static Uri _uri(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  // ── Wishlist personal ────────────────────────────────────────────────────────

  Future<WishlistData> getWishlist() async {
    final response = await _client.get(_uri('/wishlist'));
    final data = HttpResponseHandler.decodeObject(response);
    return WishlistData.fromJson(data);
  }

  Future<WishlistItem> addItem({
    String? bookId,
    required String title,
    String? author,
    String? coverUrl,
    String? isbn,
    WishlistFormat format = WishlistFormat.physical,
    WishlistPriority priority = WishlistPriority.medium,
    double? price,
    DateTime? releaseDate,
    DateTime? plannedMonth,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      if (bookId != null) 'bookId': bookId,
      if (author != null) 'author': author,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (isbn != null) 'isbn': isbn,
      'format': format.toApiValue(),
      'priority': priority.toApiValue(),
      if (price != null) 'price': price,
      if (releaseDate != null) 'releaseDate': releaseDate.toIso8601String(),
      if (plannedMonth != null) 'plannedMonth': plannedMonth.toIso8601String(),
      if (note != null) 'note': note,
    };

    final response = await _client.post(
      _uri('/wishlist'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 400 || response.statusCode == 404) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded['mensaje']?.toString() ?? 'Error al guardar el libro.',
      );
    }

    final data = HttpResponseHandler.decodeObject(response);
    return WishlistItem.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<WishlistItem> updateItem(
    String id, {
    String? title,
    String? author,
    String? coverUrl,
    String? isbn,
    WishlistFormat? format,
    WishlistPriority? priority,
    double? price,
    bool clearPrice = false,
    DateTime? releaseDate,
    bool clearReleaseDate = false,
    DateTime? plannedMonth,
    bool clearPlannedMonth = false,
    String? note,
    bool clearNote = false,
  }) async {
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (isbn != null) 'isbn': isbn,
      if (format != null) 'format': format.toApiValue(),
      if (priority != null) 'priority': priority.toApiValue(),
      if (price != null) 'price': price,
      if (clearPrice) 'price': null,
      if (releaseDate != null) 'releaseDate': releaseDate.toIso8601String(),
      if (clearReleaseDate) 'releaseDate': null,
      if (plannedMonth != null) 'plannedMonth': plannedMonth.toIso8601String(),
      if (clearPlannedMonth) 'plannedMonth': null,
      if (note != null) 'note': note,
      if (clearNote) 'note': null,
    };

    final response = await _client.patch(
      _uri('/wishlist/$id'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 404) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        statusCode: 404,
        message: decoded['mensaje']?.toString() ?? 'Ítem no encontrado.',
      );
    }

    final data = HttpResponseHandler.decodeObject(response);
    return WishlistItem.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<void> deleteItem(String id) async {
    final response = await _client.delete(_uri('/wishlist/$id'));
    if (response.statusCode == 404) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        statusCode: 404,
        message: decoded['mensaje']?.toString() ?? 'Ítem no encontrado.',
      );
    }
    HttpResponseHandler.ensureSuccess(response);
  }

  // ── Wishlist del club ────────────────────────────────────────────────────────

  Future<ClubWishlistData> getClubWishlist() async {
    final response = await _client.get(_uri('/club/wishlist'));
    final data = HttpResponseHandler.decodeObject(response);
    return ClubWishlistData.fromJson(data);
  }

  // ── Google Books — autocompletar al añadir ───────────────────────────────────

  static const _googleBooksUrl =
      'https://www.googleapis.com/books/v1/volumes';

  Future<List<GoogleBookResult>> searchBooks(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse(_googleBooksUrl).replace(queryParameters: {
      'q': query.trim(),
      'maxResults': '8',
      'langRestrict': 'es',
      'printType': 'books',
    });
    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      return items
          .cast<Map<String, dynamic>>()
          .map(GoogleBookResult.fromJson)
          .where((b) => b.title.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }
}

// ── Resultado de Google Books ──────────────────────────────────────────────────

class GoogleBookResult {
  const GoogleBookResult({
    required this.googleId,
    required this.title,
    this.author,
    this.coverUrl,
    this.isbn,
    this.publishedDate,
  });

  final String googleId;
  final String title;
  final String? author;
  final String? coverUrl;
  final String? isbn;
  final String? publishedDate; // ISO date string o "YYYY-MM" o "YYYY"

  factory GoogleBookResult.fromJson(Map<String, dynamic> json) {
    final info = json['volumeInfo'] as Map<String, dynamic>? ?? {};
    final images = info['imageLinks'] as Map<String, dynamic>? ?? {};

    // ISBN-13 preferido, fallback ISBN-10
    String? isbn;
    final identifiers =
        info['industryIdentifiers'] as List<dynamic>? ?? [];
    for (final id in identifiers.cast<Map<String, dynamic>>()) {
      if (id['type'] == 'ISBN_13') {
        isbn = id['identifier'] as String?;
        break;
      }
    }
    isbn ??= identifiers
        .cast<Map<String, dynamic>>()
        .where((id) => id['type'] == 'ISBN_10')
        .map((id) => id['identifier'] as String?)
        .firstOrNull;

    // Portada — preferir thumbnail, upgrade a HTTP→HTTPS
    final rawCover = (images['thumbnail'] ?? images['smallThumbnail']) as String?;
    final coverUrl = rawCover?.replaceFirst('http://', 'https://');

    final authors = info['authors'] as List<dynamic>? ?? [];

    return GoogleBookResult(
      googleId: json['id'] as String? ?? '',
      title: info['title'] as String? ?? '',
      author: authors.isNotEmpty ? authors.first as String : null,
      coverUrl: coverUrl,
      isbn: isbn,
      publishedDate: info['publishedDate'] as String?,
    );
  }

  /// Intenta parsear publishedDate como DateTime para comparar con hoy.
  DateTime? get releaseDateTime {
    if (publishedDate == null) return null;
    // "YYYY", "YYYY-MM", "YYYY-MM-DD"
    final parts = publishedDate!.split('-');
    try {
      final year = int.parse(parts[0]);
      final month = parts.length > 1 ? int.parse(parts[1]) : 1;
      final day = parts.length > 2 ? int.parse(parts[2]) : 1;
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  bool get isFutureRelease {
    final d = releaseDateTime;
    return d != null && d.isAfter(DateTime.now());
  }
}
