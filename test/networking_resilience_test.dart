import 'dart:convert';
import 'dart:io';

import 'package:club_lectura_app/models/auth_session.dart';
import 'package:club_lectura_app/services/api_exception.dart';
import 'package:club_lectura_app/services/auth_session_service.dart';
import 'package:club_lectura_app/services/authenticated_http_client.dart';
import 'package:club_lectura_app/services/http_response_handler.dart';
import 'package:club_lectura_app/services/api_service.dart';
import 'package:club_lectura_app/services/general_dashboard_service.dart';
import 'package:club_lectura_app/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late _MemoryStorage storage;
  final session = AuthSessionService.instance;

  setUp(() async {
    storage = _MemoryStorage();
    session.configureStorage(storage);
    await session.initialize();
    await session.establish(_session());
  });

  AuthenticatedHttpClient client(http.Client inner) => AuthenticatedHttpClient(
    inner: inner,
    session: session,
    requestTimeout: const Duration(milliseconds: 5),
    delay: (_) async {},
  );

  test('timeout produce un error tipado y conserva la sesión', () async {
    final httpClient = client(
      MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      httpClient.get(Uri.parse('https://example.test/api?action=dashboard')),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiErrorType.timeout,
        ),
      ),
    );
    expect(session.isAuthenticated, isTrue);
  });

  test('sin conexión produce un error tipado', () async {
    final httpClient = client(
      MockClient((_) async => throw const SocketException('offline')),
    );

    await expectLater(
      httpClient.get(Uri.parse('https://example.test/api?action=dashboard')),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiErrorType.noConnection,
        ),
      ),
    );
  });

  test('refresh temporalmente inaccesible no borra la sesión', () async {
    final inner = MockClient((request) async {
      if (request.url.queryParameters['action'] == 'refreshToken') {
        throw const SocketException('offline');
      }
      return http.Response(jsonEncode({'error': 'INVALID_ACCESS_TOKEN'}), 401);
    });

    await expectLater(
      client(inner).get(Uri.parse('https://example.test/api?action=dashboard')),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiErrorType.noConnection,
        ),
      ),
    );
    expect(session.isAuthenticated, isTrue);
    expect(storage.value, isNotNull);
  });

  test('un 5xx durante refresh conserva la sesión', () async {
    final inner = MockClient((request) async {
      if (request.url.queryParameters['action'] == 'refreshToken') {
        return http.Response('unavailable', 503);
      }
      return http.Response(jsonEncode({'error': 'INVALID_ACCESS_TOKEN'}), 401);
    });

    await expectLater(
      client(inner).get(Uri.parse('https://example.test/api?action=dashboard')),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiErrorType.server,
        ),
      ),
    );
    expect(session.isAuthenticated, isTrue);
    expect(storage.clearCalls, 0);
  });

  test('refresh token inválido sí expira y limpia la sesión', () async {
    final inner = MockClient((request) async {
      final refresh = request.url.queryParameters['action'] == 'refreshToken';
      return http.Response(
        jsonEncode({
          'error': refresh ? 'INVALID_REFRESH_TOKEN' : 'INVALID_ACCESS_TOKEN',
        }),
        401,
        headers: {'content-type': 'application/json'},
      );
    });

    final response = await client(
      inner,
    ).get(Uri.parse('https://example.test/api?action=dashboard'));

    expect(response.statusCode, 401);
    expect(session.isAuthenticated, isFalse);
    expect(session.sessionExpired, isTrue);
    expect(storage.value, isNull);
  });

  test(
    'varios refresh inválidos notifican la expiración una sola vez',
    () async {
      var refreshCalls = 0;
      var expiryNotifications = 0;
      void listener() {
        if (session.sessionExpired) expiryNotifications++;
      }

      session.addListener(listener);
      addTearDown(() => session.removeListener(listener));
      final inner = MockClient((request) async {
        if (request.url.queryParameters['action'] == 'refreshToken') {
          refreshCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 1));
          return http.Response(
            jsonEncode({'error': 'INVALID_REFRESH_TOKEN'}),
            401,
          );
        }
        return http.Response(
          jsonEncode({'error': 'INVALID_ACCESS_TOKEN'}),
          401,
        );
      });
      final httpClient = client(inner);

      await Future.wait([
        httpClient.get(Uri.parse('https://example.test/api?action=dashboard')),
        httpClient.get(
          Uri.parse('https://example.test/api?action=notificaciones'),
        ),
      ]);

      expect(storage.clearCalls, 1);
      expect(refreshCalls, 1);
      expect(expiryNotifications, 1);
      expect(session.sessionExpired, isTrue);
    },
  );

  test(
    'dashboard y notificaciones convergen en un único cierre de sesión',
    () async {
      var refreshCalls = 0;
      final inner = MockClient((request) async {
        if (request.url.queryParameters['action'] == 'refreshToken') {
          refreshCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        return http.Response(
          jsonEncode({'ok': false, 'error': 'UNAUTHORIZED'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });
      final authenticated = client(inner);
      final results = await Future.wait<Object?>([
        GeneralDashboardService(client: authenticated)
            .load()
            .then<Object?>((value) => value)
            .catchError((Object error) => error),
        ApiService(client: authenticated)
            .getNotificacionesPage()
            .then<Object?>((value) => value)
            .catchError((Object error) => error),
      ]);

      expect(results, everyElement(isA<ApiException>()));
      expect(refreshCalls, 1);
      expect(storage.clearCalls, 1);
      expect(session.sessionExpired, isTrue);
    },
  );

  test('429 respeta Retry-After y no se reintenta', () async {
    var calls = 0;
    final response = await client(
      MockClient((_) async {
        calls++;
        return http.Response(
          jsonEncode({'error': 'RATE_LIMITED'}),
          429,
          headers: {'content-type': 'application/json', 'retry-after': '45'},
        );
      }),
    ).get(Uri.parse('https://example.test/api?action=dashboard'));

    expect(
      () => HttpResponseHandler.decodeJson(response),
      throwsA(
        isA<ApiException>()
            .having((error) => error.type, 'type', ApiErrorType.rateLimited)
            .having(
              (error) => error.retryAfter,
              'retryAfter',
              const Duration(seconds: 45),
            ),
      ),
    );
    expect(calls, 1);
  });

  test('GET reintenta un 500 y devuelve el éxito posterior', () async {
    var calls = 0;
    final response = await client(
      MockClient((_) async {
        calls++;
        return calls == 1
            ? http.Response('proxy unavailable', 500)
            : http.Response(
                jsonEncode({'ok': true}),
                200,
                headers: {'content-type': 'application/json'},
              );
      }),
    ).get(Uri.parse('https://example.test/api?action=dashboard'));

    expect(HttpResponseHandler.decodeObject(response)['ok'], isTrue);
    expect(calls, 2);
  });

  test('dashboard con timeout y no-retry hace un solo intento', () async {
    var calls = 0;
    final httpClient = client(
      MockClient((_) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      httpClient.get(
        Uri.parse('https://example.test/api?action=dashboard'),
        headers: const {AuthenticatedHttpClient.noRetryHeader: 'true'},
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiErrorType.timeout,
        ),
      ),
    );
    expect(calls, 1);
  });

  test('una mutación 500 no se reintenta automáticamente', () async {
    var calls = 0;
    final response = await client(
      MockClient((_) async {
        calls++;
        return http.Response('error', 500);
      }),
    ).post(Uri.parse('https://example.test/api?action=enviarVotacion'));

    expect(
      () => HttpResponseHandler.decodeJson(response),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiErrorType.server,
        ),
      ),
    );
    expect(calls, 1);
  });

  test('JSON inválido y HTML 200 producen respuesta inválida', () {
    for (final response in [
      http.Response(
        '{mal formado',
        200,
        headers: {'content-type': 'application/json'},
      ),
      http.Response(
        '<html>proxy</html>',
        200,
        headers: {'content-type': 'text/html'},
      ),
      http.Response('', 200),
    ]) {
      expect(
        () => HttpResponseHandler.decodeJson(response),
        throwsA(
          isA<ApiException>().having(
            (error) => error.type,
            'type',
            ApiErrorType.invalidResponse,
          ),
        ),
      );
    }
  });
}

AuthSession _session() => const AuthSession(
  accessToken: 'access-1',
  refreshToken: 'refresh-1',
  user: AuthUser(id: 'user-1', nombre: 'Lectora', email: 'test@example.com'),
);

class _MemoryStorage implements TokenStorage {
  AuthSession? value;
  int clearCalls = 0;

  @override
  Future<void> clear() async {
    clearCalls++;
    value = null;
  }

  @override
  Future<AuthSession?> read() async => value;

  @override
  Future<void> replaceTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    value = AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: value!.user,
    );
  }

  @override
  Future<void> write(AuthSession session) async => value = session;
}
