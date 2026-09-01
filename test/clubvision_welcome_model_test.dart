import 'package:club_lectura_app/models/clubvision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lee la elegibilidad de la Clubvisión de bienvenida', () {
    final model = ClubvisionData.fromJson({
      'abierta': false,
      'estado': 'SIN_CANDIDATAS',
      'bienvenida': {
        'disponible': true,
        'esAdmin': true,
        'miembros': 4,
        'candidatas': 7,
        'minimoMiembros': 3,
        'minimoCandidatas': 5,
      },
    });

    expect(model.bienvenida.disponible, isTrue);
    expect(model.bienvenida.esAdmin, isTrue);
    expect(model.bienvenida.miembros, 4);
    expect(model.bienvenida.candidatas, 7);
  });

  test('mantiene valores seguros con un backend anterior', () {
    final model = ClubvisionData.fromJson({'abierta': false});
    expect(model.bienvenida.disponible, isFalse);
    expect(model.tipo, 'MONTHLY');
  });
}
