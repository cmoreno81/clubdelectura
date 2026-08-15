import 'dart:io';
import 'package:club_lectura_app/models/book_of_year.dart';
import 'package:club_lectura_app/pages/book_of_year_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cambia de año y el cuadro público permanece de solo lectura', (
    tester,
  ) async {
    final years = <int>[];
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: BookOfYearPage(
          profile: 'Ada',
          initialYear: DateTime.now().year,
          loadBoard: (year, editable) async {
            years.add(year);
            expect(editable, isFalse);
            return _board(year, editable: false);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Libro del año'), findsOneWidget);
    expect(find.text('Sin lecturas'), findsWidgets);

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${DateTime.now().year - 1}').last);
    await tester.pumpAndSettle();
    expect(years, [DateTime.now().year, DateTime.now().year - 1]);
    expect(tester.takeException(), isNull);
  });

  test('el perfil ajeno integra la vista previa como solo lectura', () {
    final source = File(
      'lib/pages/perfil_usuario_page.dart',
    ).readAsStringSync();
    expect(
      source,
      contains(
        'BookOfYearPreview(profile: perfil.usuario, editable: esMiPerfil)',
      ),
    );
    final preview = File(
      'lib/widgets/profile/book_of_year_preview.dart',
    ).readAsStringSync();
    expect(
      preview,
      contains("if (board == null || (!editable && !board.hasSelections))"),
    );
    expect(preview, contains('profile: editable ? null : profile'));
  });
}

BookOfYearBoard _board(int year, {required bool editable}) => BookOfYearBoard(
  year: year,
  editable: editable,
  userName: 'Ada',
  avatarUrl: '',
  hasSelections: false,
  months: List.generate(
    12,
    (index) => BookOfYearMonth(
      month: index + 1,
      locked: index > 7,
      finished: index < 7,
      eligible: const [],
    ),
  ),
  duels: const [],
  finalists: const [],
);
