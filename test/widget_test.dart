import 'package:club_lectura_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App starts on splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // La pantalla de carga se mantiene un mínimo de tiempo visible aunque
    // la sesión ya esté lista (ver _MyAppState.initState); sin avanzar el
    // reloj falso ese temporizador queda pendiente al terminar el test.
    await tester.pump(const Duration(milliseconds: 2300));
  });
}
