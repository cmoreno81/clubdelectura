import 'package:club_lectura_app/models/libro_finalizado.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json({Object? spoilers = 'sin'}) => {
  'bookId': 'b1',
  'usuario': 'Ana',
  'libro': 'Placeres mortales',
  'genero': 'Romance',
  'saga': '',
  'numSaga': '',
  'autoconclusivo': 'Si',
  'valoracion': '5',
  'resena': 'Me encantó',
  'coverUrl': '',
  'avatarUrl': '',
  if (spoilers != 'sin') 'contieneSpoilers': spoilers,
};

void main() {
  test('una reseña sin el indicador de spoilers se trata como con spoilers', () {
    expect(LibroFinalizado.fromJson(_json()).contieneSpoilers, isTrue);
  });

  test('respeta el indicador cuando llega del servidor', () {
    expect(LibroFinalizado.fromJson(_json(spoilers: false)).contieneSpoilers, isFalse);
    expect(LibroFinalizado.fromJson(_json(spoilers: true)).contieneSpoilers, isTrue);
  });
}
