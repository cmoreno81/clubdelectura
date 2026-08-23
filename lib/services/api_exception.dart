import 'dart:convert';

import 'package:http/http.dart' as http;

enum ApiErrorType {
  noConnection,
  timeout,
  sessionExpired,
  validation,
  rateLimited,
  server,
  invalidResponse,
  forbidden,
  conflict,
  unknown,
}

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.type = ApiErrorType.unknown,
    this.retryAfter,
  });

  final int statusCode;
  final String message;
  final String? code;
  final ApiErrorType type;
  final Duration? retryAfter;

  bool get isTemporary => switch (type) {
    ApiErrorType.noConnection ||
    ApiErrorType.timeout ||
    ApiErrorType.rateLimited ||
    ApiErrorType.server => true,
    _ => false,
  };

  factory ApiException.noConnection() => const ApiException(
    statusCode: 0,
    type: ApiErrorType.noConnection,
    message: 'No hay conexión. Comprueba tu red e inténtalo de nuevo.',
  );

  factory ApiException.timeout() => const ApiException(
    statusCode: 0,
    type: ApiErrorType.timeout,
    message: 'La conexión está tardando demasiado. Inténtalo de nuevo.',
  );

  factory ApiException.invalidResponse() => const ApiException(
    statusCode: 0,
    type: ApiErrorType.invalidResponse,
    message: 'El servidor ha enviado una respuesta que no se puede procesar.',
  );

  factory ApiException.fromResponse(http.Response response) {
    final body = _safeObject(response.body, response.headers);
    final code = body?['error']?.toString();
    final serverMessage = body?['mensaje']?.toString().trim();
    final retryAfter = _retryAfter(response.headers['retry-after']);
    final type = switch (response.statusCode) {
      400 || 422 => ApiErrorType.validation,
      401 => ApiErrorType.sessionExpired,
      403 => ApiErrorType.forbidden,
      409 => ApiErrorType.conflict,
      429 => ApiErrorType.rateLimited,
      >= 500 => ApiErrorType.server,
      _ => ApiErrorType.unknown,
    };
    final fallback = switch (type) {
      ApiErrorType.validation => 'Revisa los datos e inténtalo de nuevo.',
      ApiErrorType.sessionExpired =>
        'Tu sesión ha caducado. Vuelve a iniciar sesión.',
      ApiErrorType.forbidden => 'No tienes permiso para realizar esta acción.',
      ApiErrorType.conflict => 'No se ha podido completar por un conflicto.',
      ApiErrorType.rateLimited =>
        retryAfter == null
            ? 'Has hecho demasiados intentos. Espera un poco antes de continuar.'
            : 'Has hecho demasiados intentos. Podrás reintentarlo en ${_durationLabel(retryAfter)}.',
      ApiErrorType.server =>
        'El servidor no está disponible ahora mismo. Inténtalo más tarde.',
      _ => 'No se ha podido completar la operación.',
    };
    final mayUseServerMessage = switch (type) {
      ApiErrorType.validation ||
      ApiErrorType.sessionExpired ||
      ApiErrorType.forbidden ||
      ApiErrorType.conflict => true,
      _ => false,
    };
    return ApiException(
      statusCode: response.statusCode,
      message: mayUseServerMessage && serverMessage?.isNotEmpty == true
          ? serverMessage!
          : fallback,
      code: code,
      type: type,
      retryAfter: retryAfter,
    );
  }

  static Map<String, dynamic>? _safeObject(
    String raw,
    Map<String, String> headers,
  ) {
    if (raw.trim().isEmpty || !_looksLikeJson(headers, raw)) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static bool _looksLikeJson(Map<String, String> headers, String body) {
    final contentType = headers['content-type']?.toLowerCase() ?? '';
    if (contentType.contains('json')) return true;
    final trimmed = body.trimLeft();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }

  static Duration? _retryAfter(String? value) {
    if (value == null) return null;
    final seconds = int.tryParse(value.trim());
    if (seconds != null && seconds >= 0) return Duration(seconds: seconds);
    final date = DateTime.tryParse(value);
    if (date == null) return null;
    final duration = date.toUtc().difference(DateTime.now().toUtc());
    return duration.isNegative ? Duration.zero : duration;
  }

  static String _durationLabel(Duration duration) {
    if (duration.inSeconds < 60) return '${duration.inSeconds} segundos';
    final minutes = (duration.inSeconds / 60).ceil();
    return minutes == 1 ? '1 minuto' : '$minutes minutos';
  }

  @override
  String toString() => message;
}
