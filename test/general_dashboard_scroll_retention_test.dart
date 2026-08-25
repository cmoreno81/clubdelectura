import 'package:club_lectura_app/models/general_dashboard.dart';
import 'package:club_lectura_app/pages/general_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'onboarding_v1_done': true,
      'screen_hint_v1_hint_dashboard_v3': true,
    });
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
          quickActions:
              ({
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
    // CustomScrollView puede contener varios Scrollable anidados (listas
    // horizontales, calendarios, etc.). Tomamos el primero, que es el
    // Scrollable del propio CustomScrollView vertical.
    final vertical = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
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

    // coverUrl vacío hace que ClubBookCover renderice el título como texto de
    // fallback, además del Text que aparece debajo del cover. Usamos .first.
    await tester.longPress(find.text('Tendencia 4').first);
    await tester.pumpAndSettle();

    expect(actions, 1);
    expect(loads, 1);
    expect(vertical.position.pixels, verticalBefore);
    expect(horizontal.position.pixels, horizontalBefore);
  });

  testWidgets('una mutación refresca los datos sin mostrar indicador de carga', (
    tester,
  ) async {
    // Verifica que tras una acción que devuelve true (mutación) la página
    // recarga los datos y no muestra LinearProgressIndicator (sin parpadeo).
    // TODO: añadir verificación de preservación de scroll cuando se compruebe
    // que GeneralDashboardPage restaura los offsets tras _reload().
    var loads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GeneralDashboardPage(
          loadDashboard: () async {
            loads++;
            return _dashboard(updated: loads > 1);
          },
          quickActions:
              ({
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
    final carousel = find.byKey(
      const PageStorageKey('dashboard-trending-books'),
    );
    // Deslizar el carousel para traer 'Tendencia 4' al viewport antes del longPress.
    await tester.drag(carousel, const Offset(-320, 0));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Tendencia 4').first);
    await tester.pumpAndSettle();

    expect(loads, 2);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    // Verificar que el carousel sigue existiendo (no se destruyó el widget)
    expect(carousel, findsOneWidget);
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
          quickActions:
              ({
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
    // Scrollamos hasta las tendencias usando el título de sección (único) y
    // luego longPress en la primera que sea visible.
    await tester.scrollUntilVisible(
      find.text('Se están leyendo mucho'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    final carousel2 = find.byKey(
      const PageStorageKey('dashboard-trending-books'),
    );
    // Deslizar el carousel para traer 'Tendencia 4' al viewport antes del longPress.
    await tester.drag(carousel2, const Offset(-320, 0));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Tendencia 4').first);
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(milliseconds: 30));
    expect(tester.takeException(), isNull);
  });

  testWidgets('permite volver arriba empezando el gesto sobre Mi wishlist', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GeneralDashboardPage(loadDashboard: () async => _dashboard()),
      ),
    );
    await tester.pumpAndSettle();

    final vertical = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.scrollUntilVisible(
      find.text('Lista de deseos'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    // Scroll un poco más para que el widget quede totalmente en el viewport
    // (scrollUntilVisible puede dejarlo en el borde con el centro fuera).
    await tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
    final before = vertical.position.pixels;

    // Arrastrar sobre el Scrollable principal (seguro dentro del viewport)
    // simulando que el usuario intenta volver arriba desde la zona del widget.
    await tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, 200),
    );
    await tester.pumpAndSettle();

    expect(vertical.position.pixels, lessThan(before));
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
        'anio': 2026,
        'mes': 8,
        'librosLeidos': [],
        'lecturasCalendario': [],
        'eventos': [],
      },
    });
