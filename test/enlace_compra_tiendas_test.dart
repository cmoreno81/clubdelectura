import 'package:club_lectura_app/services/api_service.dart';
import 'package:club_lectura_app/widgets/libros/botones_compra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _casa({bool exacto = true}) => {
  'tienda': 'Casa del Libro',
  'url': 'https://awin1.com/x',
  'exacto': exacto,
  'formato': 'papel',
  'aviso': 'Publicidad · Enlace de afiliado.',
  'formatos': [
    {'formato': 'papel', 'etiqueta': 'Papel', 'url': 'https://awin1.com/p'},
    {'formato': 'ebook', 'etiqueta': 'Ebook', 'url': 'https://awin1.com/e'},
  ],
};

Map<String, dynamic> _amazon() => {
  'tienda': 'Amazon',
  'url': 'https://www.amazon.es/s?k=a&tag=t',
  'exacto': true,
  'formato': 'papel',
  'aviso':
      'Publicidad · Enlace de afiliado. Como afiliado de Amazon, obtengo ingresos por las compras adscritas que cumplen los requisitos aplicables.',
  'formatos': [
    {
      'formato': 'papel',
      'etiqueta': 'Papel',
      'url': 'https://www.amazon.es/s?k=a&i=stripbooks&tag=t',
    },
    {
      'formato': 'ebook',
      'etiqueta': 'Kindle',
      'url': 'https://www.amazon.es/s?k=a&i=digital-text&tag=t',
    },
  ],
};

void main() {
  test('un servidor antiguo (una sola tienda) sigue funcionando', () {
    final e = EnlaceCompra.fromJson({..._casa(), 'loTengo': false})!;
    expect(e.tienda, 'Casa del Libro');
    expect(e.otras, isEmpty);
    expect(e.formatos.every((f) => f.tienda == 'Casa del Libro'), isTrue);
  });

  test(
    'con dos tiendas la principal es Casa del Libro y Amazon va en «otras»',
    () {
      final e = EnlaceCompra.fromJson({
        ..._casa(),
        'tiendas': [_casa(), _amazon()],
        'aviso': 'Publicidad · Enlace de afiliado.',
      })!;
      expect(e.tienda, 'Casa del Libro');
      expect(e.otras.map((o) => o.tienda), ['Amazon']);
      expect(e.otras.single.formatos.map((f) => f.etiqueta), [
        'Papel',
        'Kindle',
      ]);
      expect(
        e.otras.single.formatos.every((f) => f.tienda == 'Amazon'),
        isTrue,
      );
      // La frase que exige Amazon se muestra aunque la principal sea otra.
      expect(e.avisoLegal, contains('Como afiliado de Amazon'));
    },
  );

  test(
    'un autopublicado solo en Amazon: Amazon es la principal y no hay otras',
    () {
      final e = EnlaceCompra.fromJson({
        ..._casa(exacto: false),
        'tiendas': [_amazon(), _casa(exacto: false)],
      })!;
      expect(e.tienda, 'Amazon');
      expect(e.exacto, isTrue);
      expect(e.otras, isEmpty);
    },
  );

  test('si ninguna tienda tiene el libro no hay compra', () {
    final e = EnlaceCompra.fromJson({
      ..._casa(exacto: false),
      'tiendas': [_casa(exacto: false)],
    })!;
    expect(e.exacto, isFalse);
  });

  testWidgets(
    'el botón de la ficha dice la tienda y ofrece «También en Amazon»',
    (tester) async {
      final e = EnlaceCompra.fromJson({
        ..._casa(),
        'tiendas': [_casa(), _amazon()],
      })!;
      EnlaceCompraFormato? abierto;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BotonesCompra(enlace: e, onAbierto: (f) => abierto = f),
          ),
        ),
      );
      expect(find.text('Comprar en Casa del Libro'), findsOneWidget);
      expect(find.text('También en Amazon ›'), findsOneWidget);

      await tester.tap(find.text('También en Amazon ›'));
      await tester.pumpAndSettle();
      expect(find.text('Comprar en Amazon'), findsOneWidget);
      expect(find.text('Kindle'), findsOneWidget);
      expect(find.textContaining('Como afiliado de Amazon'), findsOneWidget);
      expect(abierto, isNull);
    },
  );

  testWidgets('con una sola tienda no aparece «También en…»', (tester) async {
    final e = EnlaceCompra.fromJson({
      ..._casa(),
      'tiendas': [_casa()],
    })!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BotonesCompra(enlace: e)),
      ),
    );
    expect(find.textContaining('También en'), findsNothing);
  });
}
