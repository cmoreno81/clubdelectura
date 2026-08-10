import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/app_config.dart';
import 'api_exception.dart';
import 'auth_session_service.dart';
import 'http_response_handler.dart';

typedef RetryDelay = Future<void> Function(Duration duration);

class AuthenticatedHttpClient extends http.BaseClient {
  AuthenticatedHttpClient({
    http.Client? inner,
    AuthSessionService? session,
    this.requestTimeout = const Duration(seconds: 12),
    this.longRequestTimeout = const Duration(seconds: 90),
    this.maxSafeAttempts = 3,
    RetryDelay? delay,
    Random? random,
  }) : _inner = inner ?? http.Client(),
       _session = session ?? AuthSessionService.instance,
       _delay = delay ?? Future<void>.delayed,
       _random = random ?? Random();

  static const longTimeoutHeader = 'X-ClubReads-Long-Timeout';
  static const idempotentRequestHeader = 'X-ClubReads-Idempotent';
  static const noRetryHeader = 'X-ClubReads-No-Retry';

  final http.Client _inner;
  final AuthSessionService _session;
  final Duration requestTimeout;
  final Duration longRequestTimeout;
  final int maxSafeAttempts;
  final RetryDelay _delay;
  final Random _random;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = await request.finalize().toBytes();
    final accessTokenUsed = _session.accessToken;
    final response = await _sendWithSafeRetries(request, body, accessTokenUsed);

    if (response.statusCode != 401) return response;
    await response.stream.drain<void>();

    if (_session.refreshToken?.isNotEmpty != true) {
      await _session.expireOnce();
      return _expiredResponse(request);
    }

    final currentAccessToken = _session.accessToken;
    if (currentAccessToken != null && currentAccessToken != accessTokenUsed) {
      return _retryAfterRefresh(request, body, currentAccessToken);
    }

    final refresh = await _session.refreshOnce(_refresh);
    switch (refresh.type) {
      case _RefreshResultType.success:
        return _retryAfterRefresh(request, body, _session.accessToken);
      case _RefreshResultType.invalid:
        await _session.expireOnce();
        return _expiredResponse(request);
      case _RefreshResultType.temporaryFailure:
        throw refresh.error ?? ApiException.noConnection();
    }
  }

  Future<http.StreamedResponse> _retryAfterRefresh(
    http.BaseRequest request,
    List<int> body,
    String? accessToken,
  ) async {
    final response = await _sendOnce(request, body, accessToken);
    if (response.statusCode != 401) return response;
    await response.stream.drain<void>();
    await _session.expireOnce();
    return _expiredResponse(request);
  }

  http.StreamedResponse _expiredResponse(http.BaseRequest request) =>
      http.StreamedResponse(
        Stream.value(
          utf8.encode(
            jsonEncode({
              'ok': false,
              'error': 'INVALID_REFRESH_TOKEN',
              'mensaje': 'Tu sesión ha caducado. Inicia sesión de nuevo.',
            }),
          ),
        ),
        401,
        headers: const {'content-type': 'application/json'},
        reasonPhrase: 'Session expired',
        request: request,
      );

  Future<http.StreamedResponse> _sendWithSafeRetries(
    http.BaseRequest request,
    List<int> body,
    String? accessToken,
  ) async {
    final safe =
        request.headers[noRetryHeader] != 'true' &&
        (request.method.toUpperCase() == 'GET' ||
            request.headers[idempotentRequestHeader] == 'true');
    final attempts = safe ? maxSafeAttempts.clamp(1, 3) : 1;
    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        final response = await _sendOnce(request, body, accessToken);
        if (response.statusCode < 500 || attempt == attempts) return response;
        await response.stream.drain<void>();
        _log(request, 'HTTP ${response.statusCode}; reintento seguro $attempt');
      } on ApiException catch (error) {
        if (!safe || !error.isTemporary || attempt == attempts) rethrow;
        _log(request, 'Fallo temporal; reintento seguro $attempt');
      }
      await _delay(_backoff(attempt));
    }
    throw ApiException.noConnection();
  }

  Future<http.StreamedResponse> _sendOnce(
    http.BaseRequest request,
    List<int> body,
    String? accessToken,
  ) async {
    final timeout = request.headers[longTimeoutHeader] == 'true'
        ? longRequestTimeout
        : requestTimeout;
    try {
      final response = await _inner
          .send(_copyRequest(request, body, accessToken))
          .timeout(timeout);
      _log(request, 'HTTP ${response.statusCode}');
      return response;
    } on TimeoutException {
      _log(request, 'Timeout');
      throw ApiException.timeout();
    } on SocketException {
      _log(request, 'Sin conexión');
      throw ApiException.noConnection();
    } on http.ClientException {
      _log(request, 'Sin conexión');
      throw ApiException.noConnection();
    }
  }

  Duration _backoff(int attempt) =>
      Duration(milliseconds: 200 * (1 << (attempt - 1)) + _random.nextInt(121));

  http.Request _copyRequest(
    http.BaseRequest source,
    List<int> body,
    String? accessToken,
  ) {
    final copy = http.Request(source.method, source.url)
      ..headers.addAll(source.headers)
      ..headers.remove(longTimeoutHeader)
      ..headers.remove(idempotentRequestHeader)
      ..headers.remove(noRetryHeader)
      ..bodyBytes = body
      ..followRedirects = source.followRedirects
      ..maxRedirects = source.maxRedirects
      ..persistentConnection = source.persistentConnection;
    if (accessToken != null && accessToken.isNotEmpty) {
      copy.headers['Authorization'] = 'Bearer $accessToken';
    }
    return copy;
  }

  Future<_RefreshResult> _refresh() async {
    final refreshToken = _session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return const _RefreshResult.invalid();
    }
    try {
      final response = await _inner
          .post(
            Uri.parse('${AppConfig.baseUrl}?action=refreshToken'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(requestTimeout);
      if (response.statusCode == 401) {
        return const _RefreshResult.invalid();
      }
      if (response.statusCode == 400) {
        final code = _errorCode(response.body);
        if (code == 'INVALID_REFRESH_TOKEN' || code == 'TOKEN_REVOKED') {
          return const _RefreshResult.invalid();
        }
      }
      if (response.statusCode != 200) {
        return _RefreshResult.temporary(ApiException.fromResponse(response));
      }
      final data = HttpResponseHandler.decodeJson(response);
      if (data is! Map<String, dynamic> ||
          data['ok'] != true ||
          data['accessToken'] is! String ||
          data['refreshToken'] is! String) {
        return _RefreshResult.temporary(ApiException.invalidResponse());
      }
      await _session.replaceTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return const _RefreshResult.success();
    } on TimeoutException {
      return _RefreshResult.temporary(ApiException.timeout());
    } on SocketException {
      return _RefreshResult.temporary(ApiException.noConnection());
    } on http.ClientException {
      return _RefreshResult.temporary(ApiException.noConnection());
    } catch (_) {
      return _RefreshResult.temporary(ApiException.invalidResponse());
    }
  }

  String? _errorCode(String body) {
    try {
      final data = jsonDecode(body);
      return data is Map<String, dynamic> ? data['error']?.toString() : null;
    } catch (_) {
      return null;
    }
  }

  void _log(http.BaseRequest request, String event) {
    if (!kDebugMode) return;
    final action = request.url.queryParameters['action'];
    debugPrint(
      '[network] ${request.method} ${request.url.path}'
      '${action == null ? '' : ' action=$action'}: $event',
    );
  }

  @override
  void close() => _inner.close();
}

enum _RefreshResultType { success, invalid, temporaryFailure }

class _RefreshResult {
  const _RefreshResult.success()
    : type = _RefreshResultType.success,
      error = null;
  const _RefreshResult.invalid()
    : type = _RefreshResultType.invalid,
      error = null;
  const _RefreshResult.temporary(this.error)
    : type = _RefreshResultType.temporaryFailure;

  final _RefreshResultType type;
  final ApiException? error;
}
