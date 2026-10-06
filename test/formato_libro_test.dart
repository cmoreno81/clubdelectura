import 'package:club_lectura_app/utils/formato_libro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cualquier código o nombre antiguo se muestra como Papel / Ebook / Audiolibro', () {
    for (final v in ['FISICO', 'Físico', 'PHYSICAL', 'papel', 'Papel']) {
      expect(FormatoLibro.etiqueta(v), 'Papel', reason: v);
    }
    for (final v in ['DIGITAL', 'Digital', 'ebook', 'Ebook']) {
      expect(FormatoLibro.etiqueta(v), 'Ebook', reason: v);
    }
    for (final v in ['AUDIOLIBRO', 'AUDIOBOOK', 'Audio', 'Audiolibro', 'audio']) {
      expect(FormatoLibro.etiqueta(v), 'Audiolibro', reason: v);
    }
  });

  test('un valor desconocido o vacío no rompe ni se inventa', () {
    expect(FormatoLibro.etiqueta('Otro'), 'Otro');
    expect(FormatoLibro.etiqueta(null), '');
    expect(FormatoLibro.emoji('Otro'), '');
  });

  test('los contadores concuerdan en singular y plural', () {
    expect(FormatoLibro.conteo('papel', 7), '7 en papel');
    expect(FormatoLibro.conteo('ebook', 1), '1 ebook');
    expect(FormatoLibro.conteo('ebook', 3), '3 ebooks');
    expect(FormatoLibro.conteo('audio', 1), '1 audiolibro');
    expect(FormatoLibro.conteo('audio', 2), '2 audiolibros');
  });
}
