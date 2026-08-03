import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/app_config.dart';
import 'auth_session_service.dart';

class AuthenticatedHttpClient extends http.BaseClient {
  AuthenticatedHttpClient({
    http.Client? inner,
    AuthSessionService? session,
    this.requestTimeout = const Duration(seconds: 30),
  }) : _inner = inner ?? http.Client(),
       _session = session ?? AuthSessionService.instance;

  final http.Client _inner;
  final AuthSessionService _session;
  final Duration requestTimeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = await request.finalize().toBytes();
    final accessTokenUsed = _session.accessToken;
    final first = _copyRequest(request, body, accessTokenUsed);
    final response = await _inner.send(first).timeout(requestTimeout);

    if (response.statusCode != 401 || _session.refreshToken == null) {
      return response;
    }
    final responseBody = await response.stream.toBytes();
    if (!_isExpiredAccessToken(responseBody)) {
      return http.StreamedResponse(
        Stream.value(responseBody),
        response.statusCode,
        headers: response.headers,
        reasonPhrase: response.reasonPhrase,
        request: request,
      );
    }

    final currentAccessToken = _session.accessToken;
    if (currentAccessToken != null && currentAccessToken != accessTokenUsed) {
      return _inner
          .send(_copyRequest(request, body, currentAccessToken))
          .timeout(requestTimeout);
    }

    final refreshed = await _session.refreshOnce(_refresh);
    if (!refreshed) {
      await _session.expire();
      return http.StreamedResponse(
        const Stream<List<int>>.empty(),
        401,
        reasonPhrase: 'Session expired',
        request: request,
      );
    }

    return _inner
        .send(_copyRequest(request, body, _session.accessToken))
        .timeout(requestTimeout);
  }

  bool _isExpiredAccessToken(List<int> body) {
    try {
      final data = jsonDecode(utf8.decode(body));
      if (data is Map<String, dynamic>) {
        return data['error'] == 'INVALID_ACCESS_TOKEN' ||
            data['error'] == 'AUTHENTICATION_REQUIRED';
      }
    } catch (_) {
      // Un 401 sin contrato reconocible no provoca una renovación.
    }
    return false;
  }

  http.Request _copyRequest(
    http.BaseRequest source,
    List<int> body,
    String? accessToken,
  ) {
    final copy = http.Request(source.method, source.url)
      ..headers.addAll(source.headers)
      ..bodyBytes = body
      ..followRedirects = source.followRedirects
      ..maxRedirects = source.maxRedirects
      ..persistentConnection = source.persistentConnection;
    if (accessToken != null && accessToken.isNotEmpty) {
      copy.headers['Authorization'] = 'Bearer $accessToken';
    }
    return copy;
  }

  Future<bool> _refresh() async {
    final refreshToken = _session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _inner
          .post(
            Uri.parse('${AppConfig.baseUrl}?action=refreshToken'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(requestTimeout);
      if (response.statusCode != 200) return false;
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic> ||
          data['ok'] != true ||
          data['accessToken'] is! String ||
          data['refreshToken'] is! String) {
        return false;
      }
      await _session.replaceTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void close() => _inner.close();
}
