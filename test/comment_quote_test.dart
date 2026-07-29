import 'package:club_lectura_app/models/comentario_lectura.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interpreta una cita con el color elegido en el kit', () {
    final comentario = ComentarioLectura.fromJson({
      'id': 'comment-1',
      'libro': 'Libro',
      'capitulo': 'Capítulo 1',
      'usuario': 'Lectora',
      'fecha': '2026-07-29',
      'comentario': 'Una frase para recordar',
      'tipo': 'QUOTE',
      'color': '#C94F7C',
    });

    expect(comentario.esCita, isTrue);
    expect(comentario.color, '#C94F7C');
  });

  test('un comentario antiguo conserva el comportamiento normal', () {
    final comentario = ComentarioLectura.fromJson({
      'id': 'comment-legacy',
      'comentario': 'Comentario de la APK anterior',
    });

    expect(comentario.esCita, isFalse);
    expect(comentario.color, isEmpty);
  });
}
