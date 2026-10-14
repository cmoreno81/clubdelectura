import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:club_lectura_app/pages/kit_export_page.dart';
import 'package:club_lectura_app/widgets/atmosferas/atmosfera_ambient_layer.dart';

void main() {
  Future<void> abrir(
    WidgetTester tester,
    KitExportTipo tipo, {
    String atmosferaId = '',
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: KitExportPage(
          tipo: tipo,
          libro: 'En llamas',
          coverUrl: '',
          colores: const [
            Color(0xFF6D4BC3),
            Color(0xFFB99CEB),
            Color(0xFFF5D9E8),
          ],
          atmosferaTitulo: 'Bosque',
          atmosferaIcono: '🌲',
          atmosferaId: atmosferaId,
          valoracion: 4.5,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la story se puede pasar de 9:16 a feed 4:5', (tester) async {
    await abrir(tester, KitExportTipo.story);
    final cartel = find.byType(AspectRatio).first;
    var t = tester.getSize(cartel);
    expect(t.width / t.height, closeTo(9 / 16, 0.001));

    await tester.tap(find.text('Feed · 4:5'));
    await tester.pumpAndSettle();
    t = tester.getSize(cartel);
    expect(t.width / t.height, closeTo(4 / 5, 0.001));
    expect(find.textContaining('4:5 para publicar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el fondo de pantalla no ofrece formato feed', (tester) async {
    await abrir(tester, KitExportTipo.wallpaper);
    expect(find.text('Feed · 4:5'), findsNothing);
  });

  testWidgets('con atmósfera guardada su escena sale de fondo; sin ella, no', (
    tester,
  ) async {
    await abrir(tester, KitExportTipo.story);
    expect(find.byType(AtmosferaEscenaEstatica), findsNothing);

    await abrir(tester, KitExportTipo.story, atmosferaId: 'EPICA');
    expect(find.byType(AtmosferaEscenaEstatica), findsOneWidget);

    await abrir(tester, KitExportTipo.wallpaper, atmosferaId: 'MARINA');
    expect(find.byType(AtmosferaEscenaEstatica), findsOneWidget);
  });
}
