import 'package:club_lectura_app/models/general_dashboard.dart';
import 'package:club_lectura_app/pages/explore_catalog_page.dart';
import 'package:club_lectura_app/pages/general_dashboard_page.dart';
import 'package:club_lectura_app/pages/nuevo_libro_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_v1_done': true});
  });

  testWidgets(
    'Últimas incorporaciones permite añadir y recarga solo al crear',
    (tester) async {
      var loads = 0;
      Future<GeneralDashboard> load() async {
        loads++;
        return _dashboard();
      }

      await tester.pumpWidget(
        MaterialApp(home: GeneralDashboardPage(loadDashboard: load)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Últimas incorporaciones'), findsOneWidget);
      expect(find.text('Añadir libro'), findsOneWidget);
      expect(find.text('Ver biblioteca'), findsNothing);
      expect(loads, 1);

      await tester.tap(find.text('Añadir libro'));
      await tester.pumpAndSettle();
      expect(find.byType(NuevoLibroPage), findsOneWidget);
      Navigator.pop(tester.element(find.byType(NuevoLibroPage)), false);
      await tester.pumpAndSettle();
      expect(loads, 1);

      await tester.tap(find.text('Añadir libro'));
      await tester.pumpAndSettle();
      expect(find.byType(NuevoLibroPage), findsOneWidget);
      Navigator.pop(tester.element(find.byType(NuevoLibroPage)), true);
      await tester.pumpAndSettle();
      expect(loads, 2);
    },
  );

  testWidgets('Explorar la biblioteca continúa abriendo el explorador', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GeneralDashboardPage(loadDashboard: () async => _dashboard()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explorar la biblioteca'));
    await tester.pump();
    expect(find.byType(ExploreCatalogPage), findsOneWidget);
  });
}

GeneralDashboard _dashboard() => GeneralDashboard.fromJson(const {
  'usuario': {'nombre': 'Lectora'},
  'ultimasIncorporaciones': [
    {
      'id': 'book-1',
      'titulo': 'Una incorporación reciente',
      'autor': 'Autora',
      'genero': 'Ficción',
      'coverUrl': '',
      'fechaAlta': '2026-08-15T08:00:00.000Z',
    },
  ],
  'calendario': {'librosLeidos': [], 'lecturasCalendario': [], 'eventos': []},
});
