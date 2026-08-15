import 'dart:async';

import 'package:club_lectura_app/models/saga_oculta.dart';
import 'package:club_lectura_app/pages/hidden_series_page.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra carga y después el estado vacío', (tester) async {
    final loading = Completer<List<SagaOculta>>();
    await _pumpPage(tester, load: () => loading.future);
    expect(find.byType(CardListSkeleton), findsOneWidget);

    loading.complete(const []);
    await tester.pumpAndSettle();
    expect(find.text('No tienes sagas ocultas'), findsOneWidget);
    expect(
      find.text(
        'Las sagas que ocultes aparecerán aquí para que puedas recuperarlas.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('restaura una saga una vez y pasa inmediatamente a vacío', (
    tester,
  ) async {
    var restores = 0;
    var invalidations = 0;
    final request = Completer<void>();
    await _pumpPage(
      tester,
      load: () async => const [SagaOculta(id: 's1', nombre: 'Saga lunar')],
      restore: (id) {
        restores++;
        expect(id, 's1');
        return request.future;
      },
      onRestored: () => invalidations++,
    );
    expect(find.text('Oculta en tu perfil'), findsOneWidget);
    expect(
      find.text('Ocultar una saga no elimina sus libros ni tu progreso.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Volver a mostrar'));
    await tester.tap(find.text('Volver a mostrar'));
    await tester.pump();
    expect(restores, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    request.complete();
    await tester.pumpAndSettle();
    expect(invalidations, 1);
    expect(find.text('Saga lunar vuelve a estar visible.'), findsOneWidget);
    expect(find.text('No tienes sagas ocultas'), findsOneWidget);
  });

  testWidgets('no desborda en pantalla estrecha con texto ampliado', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpPage(
      tester,
      textScaler: const TextScaler.linear(1.8),
      load: () async => const [
        SagaOculta(id: 's1', nombre: 'Una saga con un nombre bastante largo'),
      ],
    );
    expect(find.text('Volver a mostrar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required Future<List<SagaOculta>> Function() load,
  Future<void> Function(String sagaId)? restore,
  VoidCallback? onRestored,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: HiddenSeriesPage(
          loadHiddenSeries: load,
          restoreSeries: restore ?? (_) async {},
          onSeriesRestored: onRestored,
        ),
      ),
    ),
  );
  await tester.pump();
}
