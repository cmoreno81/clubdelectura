import 'dart:io';

import 'package:club_lectura_app/widgets/libros/add_book_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Media y Sin decidir están seleccionados inicialmente', (
    tester,
  ) async {
    AddBookPreferences? result;
    await _pumpLauncher(tester, onResult: (value) => result = value);
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(_chip(tester, 'add-book-priority-MEDIA').selected, isTrue);
    expect(_chip(tester, 'add-book-format-').selected, isTrue);

    await tester.tap(find.byKey(const ValueKey('confirm-add-book')));
    await tester.pumpAndSettle();
    expect(result?.priority, 'MEDIA');
    expect(result?.format, '');
  });

  testWidgets('envía prioridad y formato elegidos una sola vez', (
    tester,
  ) async {
    var results = 0;
    AddBookPreferences? result;
    await _pumpLauncher(
      tester,
      onResult: (value) {
        results++;
        result = value;
      },
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-book-priority-ALTA')));
    await tester.tap(find.byKey(const ValueKey('add-book-format-DIGITAL')));
    await tester.tap(find.byKey(const ValueKey('confirm-add-book')));
    await tester.pumpAndSettle();

    expect(results, 1);
    expect(result?.priority, 'ALTA');
    expect(result?.format, 'DIGITAL');
  });

  testWidgets('Cancelar cierra sin devolver preferencias', (tester) async {
    var callbacks = 0;
    await _pumpLauncher(tester, onResult: (_) => callbacks++);
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(callbacks, 0);
  });

  for (final brightness in Brightness.values) {
    testWidgets('no desborda en móvil estrecho con texto grande: $brightness', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(280, 520));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: Scaffold(
              body: AddBookSheet(
                title: 'Un título de libro extraordinariamente largo',
                author: 'Una autora con un nombre también muy largo',
                coverUrl: '',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Físico'), findsOneWidget);
      expect(find.text('Audiolibro'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final selected = _chip(tester, 'add-book-priority-MEDIA');
      final colors = Theme.of(
        tester.element(find.byType(AddBookSheet)),
      ).colorScheme;
      expect(selected.labelStyle?.color, colors.onPrimary);
    });
  }

  test('todos los accesos usan la hoja compartida y no el diálogo antiguo', () {
    for (final path in const [
      'lib/widgets/libros/libro_acciones_rapidas.dart',
      'lib/pages/libros_page.dart',
      'lib/pages/explore_catalog_page.dart',
      'lib/pages/catalog_book_detail_page.dart',
      'lib/pages/sagas_page.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('showAddBookSheet'));
      expect(
        source,
        isNot(contains('showDialog<({String prioridad, String formato})>')),
      );
    }
  });
}

ChoiceChip _chip(WidgetTester tester, String key) =>
    tester.widget<ChoiceChip>(find.byKey(ValueKey(key)));

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required ValueChanged<AddBookPreferences> onResult,
}) => tester.pumpWidget(
  MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () async {
            final result = await showAddBookSheet(
              context,
              title: 'Libro de prueba',
              author: 'Autora',
            );
            if (result != null) onResult(result);
          },
          child: const Text('Abrir'),
        ),
      ),
    ),
  ),
);
