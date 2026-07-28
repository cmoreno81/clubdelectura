import 'dart:convert';

import 'package:club_lectura_app/models/auth_session.dart';
import 'package:club_lectura_app/services/auth_session_service.dart';
import 'package:club_lectura_app/services/auth_service.dart';
import 'package:club_lectura_app/services/authenticated_http_client.dart';
import 'package:club_lectura_app/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late MemoryTokenStorage storage;
  final session = AuthSessionService.instance;

  setUp(() async {
    storage = MemoryTokenStorage();
    session.configureStorage(storage);
    await session.initialize();
  });

  test('activación guarda tokens y datos de usuaria', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.queryParameters['action'], 'activarCuenta');
      expect(jsonDecode(request.body)['codigo'], '123456');
      return http.Response(jsonEncode(_sessionResponse()), 200);
    });

    await AuthService(publicClient: client, session: session).activarCuenta(
      email: 'lectora@example.com',
      codigo: '123456',
      password: 'password-segura',
    );

    expect(session.isAuthenticated, isTrue);
    expect(storage.value?.refreshToken, 'refresh-1');
    expect(session.user?.nombre, 'Lectora');
  });

  test('login conserva el contrato de sesión del backend', () async {
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body.keys, containsAll(<String>['email', 'password']));
      return http.Response(jsonEncode(_sessionResponse()), 200);
    });

    await AuthService(
      publicClient: client,
      session: session,
    ).login(email: 'lectora@example.com', password: 'password-segura');

    expect(session.accessToken, 'access-1');
    expect(session.user?.email, 'lectora@example.com');
  });

  test(
    'registro público verifica código y establece una cuenta sin club',
    () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        final action = request.url.queryParameters['action'];
        if (action == 'solicitarRegistro') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['nombre'], 'Nueva Lectora');
          expect(body['email'], 'nueva@example.com');
          return http.Response(
            jsonEncode({'ok': true, 'mensaje': 'Código enviado'}),
            200,
          );
        }
        expect(action, 'completarRegistro');
        return http.Response(jsonEncode(_sessionResponse()), 200);
      });
      final auth = AuthService(publicClient: client, session: session);

      await auth.solicitarRegistro(
        nombre: 'Nueva Lectora',
        email: 'nueva@example.com',
      );
      await auth.completarRegistro(
        email: 'nueva@example.com',
        codigo: '123456',
        password: 'password-segura',
      );

      expect(requests, 2);
      expect(session.isAuthenticated, isTrue);
    },
  );

  test('renueva, rota el refresh token y reintenta una sola vez', () async {
    await session.establish(_session());
    var protectedCalls = 0;
    var refreshCalls = 0;
    final inner = MockClient((request) async {
      if (request.url.queryParameters['action'] == 'refreshToken') {
        refreshCalls++;
        expect(jsonDecode(request.body)['refreshToken'], 'refresh-1');
        return http.Response(
          jsonEncode({
            'ok': true,
            'accessToken': 'access-2',
            'refreshToken': 'refresh-2',
            'expiresIn': 900,
          }),
          200,
        );
      }
      protectedCalls++;
      if (protectedCalls == 1) {
        expect(request.headers['Authorization'], 'Bearer access-1');
        return http.Response(
          jsonEncode({'ok': false, 'error': 'INVALID_ACCESS_TOKEN'}),
          401,
        );
      }
      expect(request.headers['Authorization'], 'Bearer access-2');
      return http.Response('ok', 200);
    });

    final response = await AuthenticatedHttpClient(
      inner: inner,
      session: session,
    ).get(Uri.parse('https://example.test/api?action=dashboard'));

    expect(response.statusCode, 200);
    expect(protectedCalls, 2);
    expect(refreshCalls, 1);
    expect(storage.value?.refreshToken, 'refresh-2');
  });

  test('recuperación establece la sesión devuelta por resetPassword', () async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode(_sessionResponse()), 200),
    );

    await AuthService(publicClient: client, session: session).resetPassword(
      email: 'lectora@example.com',
      codigo: '654321',
      password: 'password-renovada',
    );

    expect(session.isAuthenticated, isTrue);
  });

  test('logout limpia siempre la sesión local', () async {
    await session.establish(_session());
    final client = MockClient((request) async {
      expect(request.url.queryParameters['action'], 'logout');
      return http.Response(jsonEncode({'ok': true}), 200);
    });

    await AuthService(
      publicClient: client,
      authenticatedClient: client,
      session: session,
    ).logout();

    expect(session.isAuthenticated, isFalse);
    expect(storage.value, isNull);
  });

  test('una renovación fallida caduca y limpia la sesión', () async {
    await session.establish(_session());
    var calls = 0;
    final inner = MockClient((request) async {
      calls++;
      return http.Response(
        jsonEncode({
          'ok': false,
          'error': request.url.queryParameters['action'] == 'refreshToken'
              ? 'INVALID_REFRESH_TOKEN'
              : 'INVALID_ACCESS_TOKEN',
        }),
        401,
      );
    });

    final response = await AuthenticatedHttpClient(
      inner: inner,
      session: session,
    ).get(Uri.parse('https://example.test/api?action=dashboard'));

    expect(response.statusCode, 401);
    expect(calls, 2);
    expect(session.isAuthenticated, isFalse);
    expect(session.sessionExpired, isTrue);
    expect(storage.value, isNull);
  });

  test('arranque sin tokens abre el flujo de autenticación', () async {
    session.configureStorage(storage);
    var refreshCalled = false;

    await session.bootstrap(
      refreshSession: () async {
        refreshCalled = true;
        return true;
      },
    );

    expect(refreshCalled, isFalse);
    expect(session.initialized, isTrue);
    expect(session.isAuthenticated, isFalse);
  });

  test(
    'arranque renueva y rota una sesión almacenada antes de validarla',
    () async {
      storage.value = _session();
      session.configureStorage(storage);
      final client = MockClient((request) async {
        expect(request.url.queryParameters['action'], 'refreshToken');
        expect(jsonDecode(request.body)['refreshToken'], 'refresh-1');
        return http.Response(
          jsonEncode({
            'ok': true,
            'accessToken': 'access-2',
            'refreshToken': 'refresh-2',
            'expiresIn': 900,
          }),
          200,
        );
      });

      await session.bootstrap(
        refreshSession: AuthService(
          publicClient: client,
          session: session,
        ).refreshExistingSession,
      );

      expect(session.isAuthenticated, isTrue);
      expect(session.accessToken, 'access-2');
      expect(storage.value?.refreshToken, 'refresh-2');
    },
  );

  test('arranque borra una sesión almacenada si no puede renovarla', () async {
    storage.value = _session();
    session.configureStorage(storage);
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({'ok': false, 'error': 'INVALID_REFRESH_TOKEN'}),
        401,
      ),
    );

    await session.bootstrap(
      refreshSession: AuthService(
        publicClient: client,
        session: session,
      ).refreshExistingSession,
    );

    expect(session.initialized, isTrue);
    expect(session.isAuthenticated, isFalse);
    expect(session.sessionExpired, isFalse);
    expect(storage.value, isNull);
  });
}

Map<String, dynamic> _sessionResponse() => {
  'ok': true,
  'accessToken': 'access-1',
  'refreshToken': 'refresh-1',
  'expiresIn': 900,
  'usuario': {
    'id': 'user-1',
    'nombre': 'Lectora',
    'email': 'lectora@example.com',
    'avatarUrl': '',
    'activeClub': null,
    'clubs': <dynamic>[],
  },
};

AuthSession _session() => const AuthSession(
  accessToken: 'access-1',
  refreshToken: 'refresh-1',
  user: AuthUser(id: 'user-1', nombre: 'Lectora', email: 'lectora@example.com'),
);

class MemoryTokenStorage implements TokenStorage {
  AuthSession? value;

  @override
  Future<void> clear() async => value = null;

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
