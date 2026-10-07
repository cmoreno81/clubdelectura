import 'package:club_lectura_app/widgets/common/bandera_idioma.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pinta(WidgetTester tester, String codigo) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: Center(child: BanderaIdioma(codigo))),
  ),
);

void main() {
  for (final codigo in ['ca', 'eu', 'gl']) {
    testWidgets('$codigo se dibuja con la bandera de su territorio', (
      tester,
    ) async {
      await _pinta(tester, codigo);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('🌐'), findsNothing);
    });
  }

  testWidgets('el resto usa el emoji de su país y vacío el globo', (
    tester,
  ) async {
    await _pinta(tester, 'es');
    expect(find.text('🇪🇸'), findsOneWidget);
    await _pinta(tester, '');
    expect(find.text('🌐'), findsOneWidget);
  });
}
