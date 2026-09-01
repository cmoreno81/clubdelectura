import 'package:club_lectura_app/models/libros_data.dart';
import 'package:club_lectura_app/pages/libros_page.dart';
import 'package:club_lectura_app/services/atmosfera_controller.dart';
import 'package:club_lectura_app/services/atmosfera_scope.dart';
import 'package:club_lectura_app/widgets/common/url_text_field.dart';
import 'package:club_lectura_app/widgets/lectura/comentario_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('comentarios y citas usan ayudas de escritura narrativa', (
    tester,
  ) async {
    for (final isQuote in [false, true]) {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComentarioInput(
              controller: controller,
              onEnviar: () {},
              enviando: false,
              hintText: 'Escribe un comentario',
              // La categoría 2 es "Cita del libro"; sin categoría es un
              // comentario libre.
              categoriaSeleccionada: isQuote ? 2 : null,
            ),
          ),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      _expectNarrativeConfiguration(field);
    }
  });

  testWidgets('los campos URL mantienen desactivadas las ayudas narrativas', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UrlTextField(
            controller: controller,
            labelText: 'Enlace',
            hintText: 'https://example.com',
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.url);
    expect(field.textCapitalization, TextCapitalization.none);
    expect(field.autocorrect, isFalse);
    expect(field.enableSuggestions, isFalse);
    expect(field.smartDashesType, SmartDashesType.disabled);
    expect(field.smartQuotesType, SmartQuotesType.disabled);
  });

  testWidgets('el buscador de biblioteca no activa ayudas narrativas', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'screen_hint_v1_hint_biblioteca_v1': true,
    });
    final atmosphere = AtmosferaController();
    addTearDown(atmosphere.dispose);
    await tester.pumpWidget(
      AtmosferaScope(
        controller: atmosphere,
        child: MaterialApp(
          home: LibrosPage(
            loadData: () async => LibrosData(libros: [], finalizados: []),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.textInputAction, TextInputAction.search);
    expect(field.textCapitalization, TextCapitalization.none);
    expect(field.autocorrect, isFalse);
    expect(field.enableSuggestions, isFalse);
    expect(field.smartDashesType, SmartDashesType.disabled);
    expect(field.smartQuotesType, SmartQuotesType.disabled);
  });
}

void _expectNarrativeConfiguration(TextField field) {
  expect(field.textCapitalization, TextCapitalization.sentences);
  expect(field.autocorrect, isTrue);
  expect(field.enableSuggestions, isTrue);
  expect(field.smartDashesType, SmartDashesType.enabled);
  expect(field.smartQuotesType, SmartQuotesType.enabled);
  expect(field.keyboardType, TextInputType.multiline);
  expect(field.textInputAction, TextInputAction.newline);
}
