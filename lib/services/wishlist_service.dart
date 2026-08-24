import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/catalog_book.dart';
import '../models/wishlist.dart';
import '../utils/app_config.dart';
import 'api_service.dart';
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

  Future<WishlistItem> markPurchased(String id, {DateTime? purchasedAt}) async {
    final body = <String, dynamic>{
      if (purchasedAt != null) 'purchasedAt': purchasedAt.toIso8601String(),
    };
    final response = await _client.post(
      _uri('/wishlist/$id/purchased'),
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

  Future<WishlistItem> unmarkPurchased(String id) async {
    final response = await _client.delete(_uri('/wishlist/$id/purchased'));
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

  // ── Catálogo ClubReads — autocompletar al añadir ────────────────────────────

  Future<List<WishlistBookSearchResult>> searchBooks(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return const [];

    final books = await ApiService(
      client: _client,
    ).getCatalogoGeneral(query: normalized);
    final ordered = [
      ...books.where((book) => book.source == 'CLUBREADS'),
      ...books.where((book) => book.source != 'CLUBREADS'),
    ];
    return ordered
        .where((book) => book.id.isNotEmpty)
        .take(8)
        .map(WishlistBookSearchResult.fromCatalogBook)
        .toList(growable: false);
  }
}

// ── Resultado del catálogo interno ─────────────────────────────────────────────

class WishlistBookSearchResult {
  const WishlistBookSearchResult({
    this.bookId,
    required this.title,
    required this.sourceLabel,
    this.author,
    this.coverUrl,
    this.isbn,
    this.publishedDate,
  });

  final String? bookId;
  final String title;
  final String sourceLabel;
  final String? author;
  final String? coverUrl;
  final String? isbn;
  final String? publishedDate; // ISO date string o "YYYY-MM" o "YYYY"

  factory WishlistBookSearchResult.fromCatalogBook(CatalogBook book) =>
      WishlistBookSearchResult(
        bookId: book.source == 'CLUBREADS' ? book.id : null,
        title: book.title,
        sourceLabel: book.sourceLabel,
        author: book.authors.isEmpty ? null : book.authors.join(', '),
        coverUrl: book.coverUrl.trim().isEmpty ? null : book.coverUrl,
        isbn: book.isbn.trim().isEmpty ? null : book.isbn,
        publishedDate: book.publicationDate.trim().isNotEmpty
            ? book.publicationDate
            : book.publicationYear?.toString(),
      );

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
