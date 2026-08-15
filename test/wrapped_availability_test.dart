import 'dart:io';

import 'package:club_lectura_app/pages/mi_espacio_page.dart';
import 'package:club_lectura_app/pages/wrapped_page.dart';
import 'package:club_lectura_app/utils/wrapped_availability.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Wrapped comparte disponibilidad y año entre enero y diciembre', () {
    final january = WrappedAvailability(DateTime(2026, 1, 15));
    final february = WrappedAvailability(DateTime(2026, 2, 1));
    final october = WrappedAvailability(DateTime(2026, 10, 1));
    final november = WrappedAvailability(DateTime(2026, 11, 1));
    final december = WrappedAvailability(DateTime(2026, 12, 31));

    expect(january.isAvailable, isTrue);
    expect(january.wrappedYear, 2025);
    expect(february.isAvailable, isFalse);
    expect(february.daysUntilNovember, 273);
    expect(october.isAvailable, isFalse);
    expect(october.daysUntilNovember, 31);
    expect(november.isAvailable, isTrue);
    expect(december.isAvailable, isTrue);

    final profile = File(
      'lib/pages/perfil_usuario_page.dart',
    ).readAsStringSync();
    final individual = File(
      'lib/pages/mi_espacio_page.dart',
    ).readAsStringSync();
    expect(profile, contains('availability: WrappedAvailability()'));
    expect(
      individual,
      contains('final availability = WrappedAvailability(date)'),
    );
  });

  for (final date in [DateTime(2026, 2, 1), DateTime(2026, 10, 1)]) {
    testWidgets(
      '${date.month}: la tarjeta individual está bloqueada y no navega',
      (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MiEspacioWrappedCta(date: date, onTap: () => taps++),
            ),
          ),
        );

        expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
        expect(find.textContaining('Disponible en'), findsOneWidget);
        await tester.tap(find.byKey(const Key('wrapped_individual_locked')));
        await tester.pump();
        expect(taps, 0);
        expect(find.byType(WrappedPage), findsNothing);
      },
    );
  }

  for (final date in [
    DateTime(2026, 1, 15),
    DateTime(2026, 11, 1),
    DateTime(2026, 12, 1),
  ]) {
    testWidgets('${date.month}: la tarjeta individual está activa', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiEspacioWrappedCta(date: date, onTap: () => taps++),
          ),
        ),
      );

      final expectedYear = date.month == 1 ? 2025 : 2026;
      expect(find.text('Tu Wrapped $expectedYear'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
      await tester.tap(find.byKey(const Key('wrapped_individual_available')));
      expect(taps, 1);
    });
  }
}
