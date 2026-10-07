import 'package:club_lectura_app/services/api_service.dart';
import 'package:club_lectura_app/widgets/libros/botones_compra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _enlace = EnlaceCompra(
  url: 'https://tienda.test/papel',
  tienda: 'Casa del Libro',
  aviso: '',
  formato: 'papel',
  formatos: [
    EnlaceCompraFormato(
      formato: 'papel',
      etiqueta: 'Papel',
      url: 'https://tienda.test/papel',
    ),
    EnlaceCompraFormato(
      formato: 'ebook',
      etiqueta: 'Ebook',
      url: 'https://tienda.test/ebook',
    ),
  ],
);

Future<void> _pinta(WidgetTester tester, {String? principal}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BotonesCompra(enlace: _enlace, formatoPrincipal: principal),
        ),
      ),
    );

void main() {
  testWidgets('sin formato elegido se resalta el del servidor (papel)', (
    tester,
  ) async {
    await _pinta(tester);
    expect(find.widgetWithText(FilledButton, 'Papel'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Ebook'), findsOneWidget);
  });

  testWidgets('con el formato elegido en el deseo se resalta ese (ebook)', (
    tester,
  ) async {
    await _pinta(tester, principal: 'ebook');
    expect(find.widgetWithText(FilledButton, 'Ebook'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Papel'), findsOneWidget);
  });
}
