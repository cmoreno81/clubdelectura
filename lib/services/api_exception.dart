import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.code,
  });

  final int statusCode;
  final String message;
  final String? code;

  factory ApiException.fromResponse(http.Response response) {
    String? code;
    String? serverMessage;
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        code = body['error']?.toString();
        serverMessage = body['mensaje']?.toString();
      }
    } catch (_) {
      // Las respuestas no JSON se traducen por su código HTTP.
    }

    final fallback = switch (response.statusCode) {
      400 => 'Revisa los datos e inténtalo de nuevo.',
      401 => 'Los datos de acceso no son correctos.',
      403 => 'No tienes permiso para realizar esta acción.',
      405 => 'Esta operación no está disponible.',
      409 => 'Selecciona o crea un club para continuar.',
      429 => 'Demasiados intentos. Espera unos minutos.',
      _ => 'No se ha podido conectar con el servidor.',
    };
    return ApiException(
      statusCode: response.statusCode,
      message: serverMessage?.trim().isNotEmpty == true
          ? serverMessage!
          : fallback,
      code: code,
    );
  }

  @override
  String toString() => message;
}
