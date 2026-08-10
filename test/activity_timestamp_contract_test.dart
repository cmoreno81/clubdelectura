import 'package:club_lectura_app/models/capitulo_lectura.dart';
import 'package:club_lectura_app/models/conversacion_libro.dart';
import 'package:club_lectura_app/models/lectura_activa.dart';
import 'package:club_lectura_app/models/lectura_actual.dart';
import 'package:club_lectura_app/widgets/lectura/fecha_relativa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const timestamp = '2026-08-03T14:05:06.789Z';

  test('los contratos de actividad conservan el timestamp ISO', () {
    expect(
      LecturaActual.fromJson({'ultimaActividad': timestamp}).ultimaActividad,
      timestamp,
    );
    expect(
      LecturaActiva.fromJson({'ultimaActividad': timestamp}).ultimaActividad,
      timestamp,
    );
    expect(
      CapituloLectura.fromJson({'ultimaActividad': timestamp}).ultimaActividad,
      timestamp,
    );
    expect(
      ConversacionLibro.fromJson({
        'ultimaActividad': timestamp,
      }).ultimaActividad,
      timestamp,
    );
  });

  test('la ausencia de actividad se conserva como null', () {
    expect(LecturaActual.fromJson(const {}).ultimaActividad, isNull);
    expect(LecturaActiva.fromJson(const {}).ultimaActividad, isNull);
    expect(CapituloLectura.fromJson(const {}).ultimaActividad, isNull);
    expect(ConversacionLibro.fromJson(const {}).ultimaActividad, isNull);
    expect(FechaRelativa.formato(null), 'Sin actividad');
  });

  test('la presentación ISO usa fecha española completa y hora local', () {
    const localTimestamp = '2026-08-03T19:50:00';
    expect(FechaRelativa.formato(localTimestamp), '3 de agosto de 2026, 19:50');
    expect(FechaRelativa.formato(timestamp), isNot(contains('T')));
  });

  test('un valor inválido nunca expone el valor recibido', () {
    expect(
      FechaRelativa.formato('fecha-no-valida'),
      'Actividad sin fecha disponible',
    );
  });

  testWidgets('la fecha completa cabe con pantalla estrecha y texto ampliado', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Row(
              children: [
                const Icon(Icons.schedule, size: 17),
                Expanded(
                  child: Text(
                    FechaRelativa.formato('2026-08-03T19:50:00'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('3 de agosto de 2026, 19:50'), findsOneWidget);
  });
}
