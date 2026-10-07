import 'package:club_lectura_app/models/estanteria_pendientes.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> datos({List<int> pila = const [0, 0, 0]}) => {
  'ok': true,
  'pendientes': 10,
  'tengo': 4,
  'enEstanteria': 3,
  'otrosFormatos': 1,
  'anio': {'anio': 2026, 'leidos': 12, 'leidosEnCasa': 5, 'entraron': 9},
  'terminadosPapel': 21,
  'serie': [
    for (var i = 0; i < pila.length; i++)
      {'mes': '2026-0${i + 1}', 'pila': pila[i]},
  ],
};

void main() {
  test('lee las cifras y calcula cuántos faltan', () {
    final e = EstanteriaPendientes.fromJson(datos())!;
    expect(e.pendientes, 10);
    expect(e.tengo, 4);
    expect(e.faltan, 6);
    expect(e.enEstanteria, 3);
    expect(e.otrosFormatos, 1);
  });

  test('la línea de la pila solo aparece con al menos dos meses de datos', () {
    expect(EstanteriaPendientes.fromJson(datos())!.hayHistorial, isFalse);
    expect(
      EstanteriaPendientes.fromJson(datos(pila: [0, 0, 3]))!.hayHistorial,
      isFalse,
    );
    expect(
      EstanteriaPendientes.fromJson(datos(pila: [0, 2, 3]))!.hayHistorial,
      isTrue,
    );
  });

  test('el cambio del mes compara con el final del mes pasado', () {
    // Ahora hay 10 pendientes; a final del mes pasado había 14.
    final e = EstanteriaPendientes.fromJson(datos(pila: [20, 14, 10]))!;
    expect(e.cambioMes, -4);
  });

  test('el balance del año resta los nuevos a los leídos', () {
    final e = EstanteriaPendientes.fromJson(datos())!;
    expect(e.leidosAnio, 12);
    expect(e.leidosEnCasaAnio, 5);
    expect(e.entraronAnio, 9);
    expect(e.balanceAnio, 3);
    expect(e.terminadosPapelAnio, 21);
    final crece = EstanteriaPendientes.fromJson({
      ...datos(),
      'anio': {'anio': 2026, 'leidos': 2, 'entraron': 9},
    })!;
    expect(crece.balanceAnio, -7);
  });

  test('sin permiso (perfil privado) no hay estantería', () {
    expect(
      EstanteriaPendientes.fromJson({'ok': false, 'privado': true}),
      isNull,
    );
  });

  test('faltan nunca es negativo', () {
    final e = EstanteriaPendientes.fromJson({
      ...datos(),
      'pendientes': 2,
      'tengo': 5,
    })!;
    expect(e.faltan, 0);
  });
}
