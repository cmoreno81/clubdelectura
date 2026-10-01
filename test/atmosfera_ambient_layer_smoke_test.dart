import 'package:club_lectura_app/theme/atmosferas/atmosfera_tipo.dart';
import 'package:club_lectura_app/widgets/atmosferas/atmosfera_ambient_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final atmosfera in AtmosferaLectura.values) {
    testWidgets(
      'AtmosferaAmbientLayer (${atmosfera.name}) anima varios frames sin errores',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AtmosferaAmbientLayer(
                atmosfera: atmosfera,
                color: Colors.deepPurple,
                accentColor: Colors.orange,
                backgroundColor: Colors.white,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );

        // Avanza varios fotogramas del controlador (10s en bucle) para
        // recorrer distintas fases de las animaciones de cada atmósfera.
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 900));
        }

        expect(tester.takeException(), isNull);
      },
    );
  }
}
