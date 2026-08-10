import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/auth_session.dart';
import '../utils/app_config.dart';
import 'api_exception.dart';
import 'auth_session_service.dart';
import 'authenticated_http_client.dart';
import 'http_response_handler.dart';

class AuthService {
  AuthService({
    http.Client? publicClient,
    http.Client? authenticatedClient,
    AuthSessionService? session,
  }) : _publicClient = publicClient ?? http.Client(),
       _authenticatedClient = authenticatedClient ?? AuthenticatedHttpClient(),
       _session = session ?? AuthSessionService.instance;

  final http.Client _publicClient;
  final http.Client _authenticatedClient;
  final AuthSessionService _session;

  Future<String> solicitarActivacion(String email) =>
      _postMessage('solicitarActivacion', {'email': email.trim()});

  Future<String> solicitarRegistro({
    required String nombre,
    required String email,
  }) => _postMessage('solicitarRegistro', {
    'nombre': nombre.trim(),
    'email': email.trim(),
  });

  Future<void> activarCuenta({
    required String email,
    required String codigo,
    required String password,
  }) async {
    final data = await _post('activarCuenta', {
      'email': email.trim(),
      'codigo': codigo.trim(),
      'password': password,
    });
    await _saveSession(data);
  }

  Future<void> completarRegistro({
    required String email,
    required String codigo,
    required String password,
  }) async {
    final data = await _post('completarRegistro', {
      'email': email.trim(),
      'codigo': codigo.trim(),
      'password': password,
    });
    await _saveSession(data);
  }

  Future<void> login({required String email, required String password}) async {
    final data = await _post('login', {
      'email': email.trim(),
      'password': password,
    });
    await _saveSession(data);
  }

  Future<String> solicitarResetPassword(String email) =>
      _postMessage('solicitarResetPassword', {'email': email.trim()});

  Future<void> resetPassword({
    required String email,
    required String codigo,
    required String password,
  }) => _post('resetPassword', {
    'email': email.trim(),
    'codigo': codigo.trim(),
    'password': password,
  }).then(_saveSession);

  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    final response = await _authenticatedClient.post(
      _uri('cambiarPassword'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'passwordActual': passwordActual,
        'passwordNueva': passwordNueva,
      }),
    );
    _ensureSuccess(response);
  }

  Future<void> logout() async {
    try {
      await _authenticatedClient.post(
        _uri('logout'),
        headers: const {
          'Content-Type': 'application/json',
          AuthenticatedHttpClient.noRetryHeader: 'true',
        },
        body: jsonEncode(<String, dynamic>{}),
      );
    } finally {
      await _session.clear();
    }
  }

  Future<bool> refreshExistingSession() async {
    final refreshToken = _session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final data = await _post('refreshToken', {'refreshToken': refreshToken});
      if (data['ok'] != true ||
          data['accessToken'] is! String ||
          data['refreshToken'] is! String) {
        // Una respuesta correcta pero incompleta no demuestra que el refresh
        // token sea inválido. Se conserva para poder reintentar más tarde.
        return true;
      }
      await _session.replaceTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } on ApiException catch (error) {
      return error.code != 'INVALID_REFRESH_TOKEN' &&
          error.code != 'TOKEN_REVOKED';
    } catch (_) {
      return true;
    }
  }

  Future<String> _postMessage(String action, Map<String, dynamic> body) async {
    final data = await _post(action, body);
    return data['mensaje']?.toString() ?? 'Código enviado.';
  }

  Future<Map<String, dynamic>> _post(
    String action,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _publicClient
          .post(
            _uri(action),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));
      return HttpResponseHandler.decodeObject(response);
    } on TimeoutException {
      throw ApiException.timeout();
    } on SocketException {
      throw ApiException.noConnection();
    } on http.ClientException {
      throw ApiException.noConnection();
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    if (data['accessToken'] is! String ||
        data['refreshToken'] is! String ||
        data['usuario'] is! Map) {
      throw const ApiException(
        statusCode: 500,
        message: 'La respuesta de sesión no es válida.',
      );
    }
    await _session.establish(
      AuthSession(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        user: AuthUser.fromJson(
          Map<String, dynamic>.from(data['usuario'] as Map),
        ),
      ),
    );
  }

  Uri _uri(String action) =>
      Uri.parse(AppConfig.baseUrl).replace(queryParameters: {'action': action});

  void _ensureSuccess(http.Response response) {
    HttpResponseHandler.ensureSuccess(response);
  }
}
