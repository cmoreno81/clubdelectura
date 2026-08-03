import 'package:club_lectura_app/widgets/common/club_book_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('acepta un ancho infinito dentro de una cuadrícula', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 110,
            child: ClubBookCover(
              title: 'Libro de prueba',
              imageUrl: 'https://example.invalid/cover.jpg',
              width: double.infinity,
              height: 140,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ClubBookCover), findsOneWidget);
  });
}
