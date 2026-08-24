import 'package:http/http.dart' as http;

import '../models/upcoming_release.dart';
import '../utils/app_config.dart';
import 'authenticated_http_client.dart';
import 'http_response_handler.dart';

class UpcomingReleasesService {
  UpcomingReleasesService({http.Client? client})
    : _client = client ?? AuthenticatedHttpClient();

  final http.Client _client;

  Future<List<UpcomingRelease>> load({
    DateTime? from,
    DateTime? to,
    String? genre,
    int limit = 40,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/books/upcoming').replace(
      queryParameters: {
        'limit': '$limit',
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
        if (genre != null && genre.trim().isNotEmpty) 'genre': genre.trim(),
      },
    );
    final data = HttpResponseHandler.decodeObject(await _client.get(uri));
    final rawItems = data['items'] ?? data['libros'] ?? data['lanzamientos'];
    return (rawItems as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(_parseRelease)
        .whereType<UpcomingRelease>()
        .toList(growable: false);
  }

  Future<List<UpcomingRelease>> loadNew({int limit = 40}) async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/books/new-releases',
    ).replace(queryParameters: {'limit': '$limit'});
    final data = HttpResponseHandler.decodeObject(await _client.get(uri));
    final rawItems = data['items'] ?? data['libros'] ?? data['novedades'];
    return (rawItems as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(_parseRelease)
        .whereType<UpcomingRelease>()
        .toList(growable: false);
  }

  UpcomingRelease? _parseRelease(Map<dynamic, dynamic> item) {
    try {
      final release = UpcomingRelease.fromJson(Map<String, dynamic>.from(item));
      return release.title.trim().isEmpty || release.id.trim().isEmpty
          ? null
          : release;
    } catch (_) {
      // Un registro incompleto de la fuente no debe ocultar los demás.
      return null;
    }
  }
}
