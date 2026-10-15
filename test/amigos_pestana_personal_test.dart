import 'package:club_lectura_app/models/amistad.dart';
import 'package:club_lectura_app/pages/amistades_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Amigos como pestaña: sin flecha atrás y con el resumen arriba', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AmistadesPage(
          embebida: true,
          cargar: () async => const AmistadesData(
            miCodigo: 'ABCD-2345',
            amistades: [PersonaAmistad(nombre: 'Marta')],
            recibidas: [
              PersonaAmistad(nombre: 'Sara'),
              PersonaAmistad(nombre: 'Leo'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('amistades-resumen')), findsOneWidget);
    expect(find.text('por responder'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    expect(find.text('ABCD-2345'), findsOneWidget);
  });

  testWidgets('Amigos suelto (desde Inicio) no enseña el resumen de pestaña', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AmistadesPage(cargar: () async => const AmistadesData()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('amistades-resumen')), findsNothing);
  });
}
