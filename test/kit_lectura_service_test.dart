import 'package:club_lectura_app/models/auth_session.dart';
import 'package:club_lectura_app/models/kit_lectura_seleccion.dart';
import 'package:club_lectura_app/services/auth_session_service.dart';
import 'package:club_lectura_app/services/kit_lectura_service.dart';
import 'package:club_lectura_app/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Almacen implements TokenStorage {
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

/// Servidor falso: guarda un kit por libro, o falla si [caido].
class _Remoto implements KitLecturaRemoto {
  final Map<String, Map<String, dynamic>> kits = {};
  final Map<String, DateTime> fechas = {};
  bool caido = false;
  int escrituras = 0;

  @override
  Future<({bool ok, Map<String, dynamic>? kit, DateTime? actualizado})> leer(
    String bookId,
  ) async {
    if (caido) return (ok: false, kit: null, actualizado: null);
    return (ok: true, kit: kits[bookId], actualizado: fechas[bookId]);
  }

  @override
  Future<DateTime?> escribir(String bookId, Map<String, dynamic> kit) async {
    if (caido) return null;
    escrituras++;
    kits[bookId] = kit;
    return fechas[bookId] = DateTime.now().add(
      Duration(milliseconds: escrituras),
    );
  }
}

void main() {
  final sesion = AuthSessionService.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sesion.configureStorage(_Almacen());
    await sesion.initialize();
    await sesion.establish(
      const AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        user: AuthUser(id: 'u1', nombre: 'Cris', email: 'c@test.es'),
      ),
    );
  });

  const kit = KitLecturaSeleccion(paleta: ['#ff0000', '#00ff00']);

  test('al guardar, el kit queda en la cuenta además del móvil', () async {
    final remoto = _Remoto();
    await KitLecturaService(remoto: remoto).guardar('b1', kit);
    expect(remoto.kits['b1']!['paleta'], ['#ff0000', '#00ff00']);
  });

  test('tras reinstalar (móvil vacío) se recupera de la cuenta', () async {
    final remoto = _Remoto();
    await KitLecturaService(remoto: remoto).guardar('b1', kit);

    SharedPreferences.setMockInitialValues({}); // app reinstalada
    final recuperado = await KitLecturaService(remoto: remoto).obtener('b1');
    expect(recuperado.paleta, ['#ff0000', '#00ff00']);
  });

  test('un kit que solo estaba en el móvil se sube a la cuenta', () async {
    SharedPreferences.setMockInitialValues({
      'kit_lectura_u1_b1': '{"paleta":["#123456"]}',
    });
    final remoto = _Remoto();
    final servicio = KitLecturaService(remoto: remoto);
    await servicio.subirPendientes();
    expect(remoto.kits['b1']!['paleta'], ['#123456']);
    // Ya sincronizado: otra pasada no vuelve a subirlo.
    await servicio.subirPendientes();
    expect(remoto.escrituras, 1);
  });

  test('sin conexión se usa el móvil y no se pierde nada', () async {
    final remoto = _Remoto()..caido = true;
    final servicio = KitLecturaService(remoto: remoto);
    await servicio.guardar('b1', kit);
    final leido = await servicio.obtener('b1');
    expect(leido.paleta, ['#ff0000', '#00ff00']);
    expect(remoto.kits, isEmpty);

    // Vuelve la conexión: el cambio pendiente sube solo.
    remoto.caido = false;
    await servicio.subirPendientes();
    expect(remoto.kits['b1']!['paleta'], ['#ff0000', '#00ff00']);
  });

  test(
    'si la cuenta tiene un kit y el móvil uno antiguo sin fecha, manda la cuenta',
    () async {
      final remoto = _Remoto();
      await KitLecturaService(remoto: remoto).guardar('b1', kit);
      SharedPreferences.setMockInitialValues({
        'kit_lectura_u1_b1': '{"paleta":["#000000"]}',
      });
      final leido = await KitLecturaService(remoto: remoto).obtener('b1');
      expect(leido.paleta, ['#ff0000', '#00ff00']);
    },
  );
}
