import 'package:club_lectura_app/pages/nuevo_libro_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'screen_hint_v1_hint_nuevo_libro_v1': true,
    });
  });

  testWidgets('el alta ofrece catalán, euskera y gallego y «Otro idioma»', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: NuevoLibroPage()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Otro idioma…'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Catalán'), findsOneWidget);
    expect(find.textContaining('Euskera'), findsOneWidget);
    expect(find.textContaining('Gallego'), findsOneWidget);
    expect(find.text('Otro idioma…'), findsOneWidget);
    // Los poco habituales no ocupan sitio hasta abrir «Otro idioma».
    expect(find.textContaining('Coreano'), findsNothing);

    await tester.ensureVisible(find.text('Otro idioma…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otro idioma…'));
    await tester.pumpAndSettle();
    expect(find.text('Coreano'), findsOneWidget);
    await tester.tap(find.text('Coreano'));
    await tester.pumpAndSettle();
    // El elegido queda a la vista como un chip más.
    expect(find.textContaining('Coreano'), findsOneWidget);
  });
}
