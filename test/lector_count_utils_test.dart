import 'package:club_lectura_app/utils/lector_count_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pluraliza lectores interesados', () {
    expect(lectoresInteresadosLabel(0), 'lectores interesados');
    expect(lectoresInteresadosLabel(1), 'lector interesado');
    expect(lectoresInteresadosLabel(2), 'lectores interesados');
  });

  test('pluraliza libros leídos', () {
    expect(librosLeidosLabel(1), 'leído');
    expect(librosLeidosLabel(2), 'leídos');
  });
}
