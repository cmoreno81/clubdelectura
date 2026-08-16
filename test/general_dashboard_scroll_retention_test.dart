import 'package:club_lectura_app/models/general_dashboard.dart';
import 'package:club_lectura_app/pages/general_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_v1_done': true});
  });

  testWidgets('cancelar acciones conserva el scroll vertical y de tendencias', (
    tester,
  ) async {
    var loads = 0;
    var actions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GeneralDashboardPage(
          loadDashboard: () async {
            loads++;
            return _dashboard();
          },
          quickActions: ({
            required title,
            required bookId,
            required coverUrl,
            required genre,
            required author,
          }) async {
            actions++;
            return false;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Se están leyendo mucho'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    final vertical = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    final carousel = find.byKey(
      const PageStorageKey('dashboard-trending-books'),
    );
    await tester.drag(carousel, const Offset(-320, 0));
    await tester.pumpAndSettle();
    final horizontal = tester.state<ScrollableState>(
      find.descendant(of: carousel, matching: find.byType(Scrollable)),
    );
    final verticalBefore = vertical.position.pixels;
    final horizontalBefore = horizontal.position.pixels;

    await tester.longPress(find.text('Tendencia 4'));
    await tester.pumpAndSettle();

    expect(actions, 1);
    expect(loads, 1);
    expect(vertical.position.pixels, verticalBefore);
    expect(horizontal.position.pixels, horizontalBefore);
  });

  testWidgets('una mutación refresca sin parpadeo ni perder ambos offsets', (
    tester,
  ) async {
    var loads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GeneralDashboardPage(
          loadDashboard: () async {
            loads++;
            return _dashboard(updated: loads > 1);
          },
          quickActions: ({
            required title,
            required bookId,
            required coverUrl,
            required genre,
            required author,
          }) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Se están leyendo mucho'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    final vertical = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    final carousel = find.byKey(
      const PageStorageKey('dashboard-trending-books'),
    );
    await tester.drag(carousel, const Offset(-300, 0));
    await tester.pumpAndSettle();
    final horizontal = tester.state<ScrollableState>(
      find.descendant(of: carousel, matching: find.byType(Scrollable)),
    );
    final verticalBefore = vertical.position.pixels;
    final horizontalBefore = horizontal.position.pixels;

    await tester.longPress(find.text('Tendencia 4'));
    await tester.pumpAndSettle();

    expect(loads, 2);
    expect(find.text('Tendencia actualizada'), findsOneWidget);
    expect(find.text('Tendencia 4'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(vertical.position.pixels, verticalBefore);
    expect(horizontal.position.pixels, horizontalBefore);
  });

  testWidgets('desmontar durante una actualización no produce errores', (
    tester,
  ) async {
    var loads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GeneralDashboardPage(
          loadDashboard: () async {
            loads++;
            if (loads > 1) {
              await Future<void>.delayed(const Duration(milliseconds: 20));
            }
            return _dashboard();
          },
          quickActions: ({
            required title,
            required bookId,
            required coverUrl,
            required genre,
            required author,
          }) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Último 0'));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(milliseconds: 30));
    expect(tester.takeException(), isNull);
  });
}

GeneralDashboard _dashboard({bool updated = false}) =>
    GeneralDashboard.fromJson({
      'usuario': {'nombre': 'Lectora'},
      'ultimasIncorporaciones': List.generate(
        8,
        (index) => {
          'id': 'latest-$index',
          'titulo': 'Último $index',
          'autor': 'Autora',
          'genero': 'Ficción',
          'coverUrl': '',
        },
      ),
      'miBiblioteca': List.generate(
        8,
        (index) => {
          'id': 'personal-$index',
          'titulo': 'Pendiente $index',
          'genero': 'Ficción',
          'prioridad': 'ALTA',
          'estado': 'PENDIENTE',
          'coverUrl': '',
        },
      ),
      'tendencias': List.generate(
        8,
        (index) => {
          'id': 'trend-$index',
          'titulo': updated && index == 4
              ? 'Tendencia actualizada'
              : 'Tendencia $index',
          'coverUrl': '',
          'lectoras': index + 1,
        },
      ),
      'calendario': {
        'librosLeidos': [],
        'lecturasCalendario': [],
        'eventos': [],
      },
    });
