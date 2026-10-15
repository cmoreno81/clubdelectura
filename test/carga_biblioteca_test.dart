import 'dart:async';
import 'dart:convert';

import 'package:club_lectura_app/services/api_service.dart';
import 'package:club_lectura_app/widgets/libros/cargando_biblioteca.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'las dos listas de la Biblioteca se piden a la vez, no una tras otra',
    () async {
      final pendientes = <String, Completer<http.Response>>{};
      final client = MockClient((request) {
        final accion = request.url.queryParameters['action']!;
        final c = Completer<http.Response>();
        pendientes[accion] = c;
        return c.future;
      });
      final api = ApiService(client: client);

      final futuro = api.getLibrosDataGlobal();
      await Future<void>.delayed(Duration.zero);
      // Antes de contestar a la primera, la segunda ya se ha pedido.
      expect(
        pendientes.keys,
        containsAll(['librosGlobal', 'librosFinalizadosTodosGlobal']),
      );

      for (final c in pendientes.values) {
        c.complete(
          http.Response(
            jsonEncode(<dynamic>[]),
            200,
            headers: {'content-type': 'application/json'},
          ),
        );
      }
      final datos = await futuro;
      expect(datos.libros, isEmpty);
      expect(datos.finalizados, isEmpty);
    },
  );

  testWidgets('el aviso de carga cambia con el tiempo y ofrece reintentar', (
    tester,
  ) async {
    var reintentos = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CargandoBiblioteca(
            onReintentar: () => reintentos++,
            avisoLento: const Duration(seconds: 6),
            avisoMuyLento: const Duration(seconds: 20),
          ),
        ),
      ),
    );
    expect(find.text('Cargando tu biblioteca…'), findsOneWidget);
    expect(
      find.byKey(const Key('cargando-biblioteca-reintentar')),
      findsNothing,
    );

    await tester.pump(const Duration(seconds: 7));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Está tardando más de lo normal…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 14));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('La conexión va lenta'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cargando-biblioteca-reintentar')));
    expect(reintentos, 1);
  });
}
