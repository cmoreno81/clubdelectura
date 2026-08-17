import 'package:club_lectura_app/pages/ayuda_page.dart';
import 'package:club_lectura_app/widgets/common/onboarding_tutorial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Ayuda describe Historial unificado y Wrapped en Favoritos', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AyudaPage()));

    final section = find.text('Estadísticas y perfil');
    await tester.scrollUntilVisible(section, 500);
    await tester.tap(section);
    await tester.pumpAndSettle();

    final profileQuestion = find.text('¿Qué son las secciones del perfil?');
    await tester.ensureVisible(profileQuestion);
    await tester.pumpAndSettle();
    await tester.tap(profileQuestion);
    await tester.pumpAndSettle();

    expect(find.textContaining('"Historial" tiene dos vistas'), findsOneWidget);
    expect(
      find.textContaining('"Favoritos" reúne Libros favoritos'),
      findsOneWidget,
    );
    expect(find.textContaining('"Timeline" muestra'), findsNothing);
    expect(find.textContaining('"Finalizados" lista'), findsNothing);

    final trackingQuestion = find.text(
      '¿Qué es "Seguimiento de lectura" en el perfil?',
    );
    await tester.ensureVisible(trackingQuestion);
    await tester.pumpAndSettle();
    await tester.tap(trackingQuestion);
    await tester.pumpAndSettle();
    expect(find.textContaining('Wrapped no está aquí'), findsOneWidget);
  });

  testWidgets('el tutorial presenta la navegación actual del Perfil', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => mostrarOnboardingTutorial(context),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('¡Te damos la bienvenida a ClubReads!'), findsOneWidget);

    for (var step = 0; step < 5; step++) {
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Tu Perfil lector'), findsOneWidget);
    expect(
      find.textContaining('Historial reúne Cronología y Libros'),
      findsOneWidget,
    );
    expect(find.textContaining('Mi libro del año y Wrapped'), findsOneWidget);
  });
}
