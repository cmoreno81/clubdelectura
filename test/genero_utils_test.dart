import 'package:club_lectura_app/utils/genero_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('No ficción tiene una identidad visual propia', () {
    expect(iconoGenero('No ficción'), '🧠');
    expect(iconoGenero('No ficcion'), '🧠');
  });
}
