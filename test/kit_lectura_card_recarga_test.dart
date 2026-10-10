import 'package:club_lectura_app/models/kit_lectura_seleccion.dart';
import 'package:club_lectura_app/services/kit_lectura_service.dart';
import 'package:club_lectura_app/widgets/libros/kit_lectura_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget tarjeta(Key key) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: KitLecturaCard(key: key, bookId: 'b1', onTap: () {}),
      ),
    ),
  );

  testWidgets('al cambiar la clave la tarjeta recarga el kit guardado', (
    tester,
  ) async {
    await tester.pumpWidget(tarjeta(const ValueKey('kit-0')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Prepara una experiencia'), findsOneWidget);

    // La lectora guarda una paleta en la pantalla del kit y vuelve al libro.
    await KitLecturaService().guardar(
      'b1',
      const KitLecturaSeleccion(
        paleta: ['#D62839', '#141416', '#F9D71C', '#5DBB63', '#7B1E2E'],
      ),
    );
    await tester.pumpWidget(tarjeta(const ValueKey('kit-1')));
    await tester.pumpAndSettle();

    expect(find.text('1 de 6 preparadas'), findsOneWidget);
  });
}
