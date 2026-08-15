import 'dart:async';
import 'dart:convert';

import 'package:club_lectura_app/models/auth_session.dart';
import 'package:club_lectura_app/services/api_service.dart';
import 'package:club_lectura_app/services/auth_session_service.dart';
import 'package:club_lectura_app/services/favoritos_service.dart';
import 'package:club_lectura_app/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late AuthSessionService session;

  setUp(() {
    session = AuthSessionService.instance;
    session.configureStorage(_MemoryTokenStorage());
  });

  test('A con cinco favoritos no se muestra durante la carga de B', () async {
    final responseA = Completer<http.Response>();
    final service = FavoritosService.forTesting(
      ApiService(
        client: MockClient((request) {
          final profile = request.url.queryParameters['perfil'];
          if (profile == 'Cuenta A') return responseA.future;
          return Future.value(_favoritesResponse(const []));
        }),
      ),
      session: session,
    );

    await session.establish(_session('a', 'Cuenta A'));
    final pendingA = service.cargar();
    responseA.complete(
      _favoritesResponse(
        List.generate(5, (index) => _favorite('a-$index', 'Libro A $index')),
      ),
    );
    await pendingA;
    expect(service.favoritos, hasLength(5));

    await session.clear();
    await session.establish(_session('b', 'Cuenta B'));
    final pendingB = service.cargar();
    expect(service.favoritos, isEmpty);
    expect(service.ownerUserId, 'b');
    await pendingB;
    expect(service.favoritos, isEmpty);
  });

  test(
    'una respuesta lenta de A no puede sobrescribir los favoritos de B',
    () async {
      final responseA = Completer<http.Response>();
      final service = FavoritosService.forTesting(
        ApiService(
          client: MockClient((request) {
            final profile = request.url.queryParameters['perfil'];
            if (profile == 'Cuenta A') return responseA.future;
            return Future.value(
              _favoritesResponse([_favorite('b-1', 'Libro B')]),
            );
          }),
        ),
        session: session,
      );

      await session.establish(_session('a', 'Cuenta A'));
      final pendingA = service.cargar();
      await session.establish(_session('b', 'Cuenta B'));
      await service.cargar();
      expect(service.favoritos.single.title, 'Libro B');

      responseA.complete(_favoritesResponse([_favorite('a-1', 'Libro A')]));
      await pendingA;
      expect(service.ownerUserId, 'b');
      expect(service.favoritos.single.title, 'Libro B');
    },
  );

  test('volver a A no reutiliza los datos cargados para B', () async {
    final service = FavoritosService.forTesting(
      ApiService(
        client: MockClient((request) async {
          final profile = request.url.queryParameters['perfil'];
          return _favoritesResponse([
            _favorite(profile == 'Cuenta A' ? 'a-1' : 'b-1', 'Libro $profile'),
          ]);
        }),
      ),
      session: session,
    );
    await session.establish(_session('a', 'Cuenta A'));
    await service.cargar();
    await session.establish(_session('b', 'Cuenta B'));
    expect(service.favoritos, isEmpty);
    await service.cargar();
    await session.establish(_session('a', 'Cuenta A'));
    expect(service.favoritos, isEmpty);
    await service.cargar();
    expect(service.favoritos.single.id, 'a-1');
  });
}

AuthSession _session(String id, String name) => AuthSession(
  accessToken: 'access-$id',
  refreshToken: 'refresh-$id',
  user: AuthUser(id: id, nombre: name, email: '$id@example.test'),
);

Map<String, dynamic> _favorite(String id, String title) => {
  'id': id,
  'title': title,
  'coverUrl': 'https://example.test/$id.jpg',
  'authorName': 'Autor de prueba',
};

http.Response _favoritesResponse(List<Map<String, dynamic>> favorites) =>
    http.Response(jsonEncode({'ok': true, 'favoritos': favorites}), 200);

class _MemoryTokenStorage implements TokenStorage {
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
    final current = value;
    if (current == null) return;
    value = AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: current.user,
    );
  }

  @override
  Future<void> write(AuthSession session) async => value = session;
}
