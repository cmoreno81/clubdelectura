import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

class HttpResponseHandler {
  const HttpResponseHandler._();

  static dynamic decodeJson(http.Response response) {
    ensureSuccess(response);
    final body = response.body.trim();
    if (body.isEmpty || !_looksLikeJson(response, body)) {
      throw ApiException.invalidResponse();
    }
    try {
      return jsonDecode(body);
    } catch (_) {
      throw ApiException.invalidResponse();
    }
  }

  static Map<String, dynamic> decodeObject(http.Response response) {
    final decoded = decodeJson(response);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException.invalidResponse();
    }
    return decoded;
  }

  static List<dynamic> decodeList(http.Response response) {
    final decoded = decodeJson(response);
    if (decoded is! List<dynamic>) throw ApiException.invalidResponse();
    return decoded;
  }

  static void ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromResponse(response);
    }
  }

  static bool _looksLikeJson(http.Response response, String body) {
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    if (contentType.contains('json')) return true;
    final trimmed = body.trimLeft();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }
}
