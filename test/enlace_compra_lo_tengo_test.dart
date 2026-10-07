import 'package:club_lectura_app/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> base() => {
    'url': 'https://tienda.test/libro',
    'tienda': 'Casa del Libro',
    'aviso': 'Publicidad',
    'formato': 'papel',
    'formatos': const [],
  };

  test('loTengo y enBiblioteca se leen de la respuesta', () {
    final e = EnlaceCompra.fromJson({
      ...base(),
      'loTengo': true,
      'enBiblioteca': true,
    })!;
    expect(e.loTengo, isTrue);
    expect(e.enBiblioteca, isTrue);
  });

  test('sin esos campos (backend antiguo) se ofrece la compra como siempre', () {
    final e = EnlaceCompra.fromJson(base())!;
    expect(e.loTengo, isFalse);
    expect(e.enBiblioteca, isFalse);
  });
}
