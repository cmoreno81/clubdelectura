import 'package:club_lectura_app/utils/genero_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un género con otra grafía se reconoce, y uno desconocido se respeta', () {
    expect(
      canonicoGenero('ciencia ficción', generosSoportados),
      'Ciencia ficción',
    );
    expect(
      canonicoGenero(' Novela Histórica ', generosSoportados),
      'Novela histórica',
    );
    expect(canonicoGenero('Fantasía', generosSoportados), 'Fantasía');
    // «Fiction» no está entre los elegibles: se queda tal cual para poder enseñarlo y quitarlo.
    expect(canonicoGenero('Fiction', generosSoportados), 'Fiction');
    expect(
      generosSoportados.contains(canonicoGenero('Fiction', generosSoportados)),
      isFalse,
    );
  });
}
