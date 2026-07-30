import 'package:club_lectura_app/models/libro.dart';
import 'package:club_lectura_app/models/libro_finalizado.dart';
import 'package:club_lectura_app/models/nuevo_libro.dart';
import 'package:club_lectura_app/models/perfil_usuario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el formato recibido pertenece al registro personal del libro', () {
    final libro = Libro.fromJson({
      'bookId': 'book-1',
      'usuario': 'Ana',
      'libro': 'Persépolis',
      'prioridad': 'ALTA',
      'formato': 'DIGITAL',
    });

    expect(libro.prioridad, 'ALTA');
    expect(libro.formato, 'DIGITAL');
    expect(libro.copyWith(formato: 'FISICO').formato, 'FISICO');
  });

  test('un libro nuevo envía prioridad y formato al backend', () {
    final json = NuevoLibro(
      usuario: 'Ana',
      libro: 'Persépolis',
      genero: 'Cómic',
      saga: '',
      numSaga: '',
      autoconclusivo: 'Si',
      prioridad: 'Alta',
      formato: 'FISICO',
    ).toJson();

    expect(json['genero'], 'Cómic');
    expect(json['prioridad'], 'Alta');
    expect(json['formato'], 'FISICO');
  });

  test('una finalización identifica que el libro ya es mío', () {
    final finalizado = LibroFinalizado.fromJson({
      'bookId': 'book-1',
      'usuario': 'Ana',
      'libro': 'Persépolis',
      'yaLoTengo': true,
    });

    expect(finalizado.yaLoTengo, isTrue);
  });

  test('el perfil interpreta el progreso y el siguiente libro de una saga', () {
    final perfil = PerfilUsuario.fromJson({
      'usuario': 'Ana',
      'resumen': <String, dynamic>{'clubes': 2, 'sagasAbiertas': 1},
      'sagas': [
        {
          'id': 'saga-1',
          'nombre': 'Los habitantes del aire',
          'autor': 'Holly Black',
          'leidos': 2,
          'totalConocidos': 3,
          'totalSaga': 3,
          'estado': 'EN_CURSO',
          'estadoEditorial': 'ONGOING',
          'volumenes': [
            {
              'bookId': 'book-1',
              'titulo': 'El príncipe cruel',
              'numero': '1',
              'posicion': 1,
              'estado': 'LEIDO',
            },
            {
              'bookId': 'book-2',
              'titulo': 'El rey malvado',
              'numero': '2',
              'posicion': 2,
              'estado': 'LEIDO',
            },
            {
              'bookId': 'book-3',
              'titulo': 'La reina de nada',
              'numero': '3',
              'posicion': 3,
              'estado': 'PENDIENTE',
            },
          ],
          'siguiente': {
            'bookId': 'book-3',
            'titulo': 'La reina de nada',
            'numero': '3',
            'estado': 'PENDIENTE',
          },
        },
      ],
    });

    expect(perfil.sagas.single.nombre, 'Los habitantes del aire');
    expect(perfil.sagas.single.leidos, 2);
    expect(perfil.sagas.single.siguiente?.titulo, 'La reina de nada');
    expect(perfil.sagas.single.estadoEditorial, 'ONGOING');
    expect(perfil.resumen.clubes, 2);
    expect(perfil.resumen.sagasAbiertas, 1);
  });

  test('una saga antigua conserva un estado editorial seguro', () {
    final saga = PerfilSaga.fromJson({
      'id': 'saga-antigua',
      'nombre': 'Saga sin metadatos',
      'leidos': 1,
      'totalConocidos': 1,
      'totalSaga': 1,
      'estado': 'AL_DIA',
    });

    expect(saga.estadoEditorial, 'UNKNOWN');
    expect(saga.alDia, isTrue);
    expect(saga.completada, isFalse);
  });

  test('una saga sin libros leídos se muestra como pendiente', () {
    final saga = PerfilSaga.fromJson({
      'id': 'saga-2',
      'nombre': 'Fae & Alchemy',
      'autor': 'Callie Hart',
      'leidos': 0,
      'totalConocidos': 3,
      'totalSaga': 3,
      'estado': 'PENDIENTE',
      'volumenes': [
        {'bookId': '1', 'titulo': 'Libro 1', 'numero': '1'},
        {'bookId': '2', 'titulo': 'Libro 2', 'numero': '2'},
        {'bookId': '3', 'titulo': 'Libro 3', 'numero': '3'},
      ],
    });

    expect(saga.pendiente, isTrue);
    expect(saga.totalSaga, 3);
    expect(saga.volumenes, hasLength(3));
  });

  test(
    'una saga editorialmente cerrada no está finalizada si faltan libros',
    () {
      final incompleta = PerfilSaga.fromJson({
        'id': 'crimson-moth',
        'nombre': 'Crimson Moth',
        'leidos': 1,
        'totalConocidos': 1,
        'totalSaga': 2,
        'estado': 'COMPLETADA',
        'estadoEditorial': 'COMPLETED',
      });
      final completa = PerfilSaga.fromJson({
        'id': 'rey-pastor',
        'nombre': 'El rey pastor',
        'leidos': 2,
        'totalConocidos': 2,
        'totalSaga': 2,
        'estado': 'COMPLETADA',
        'estadoEditorial': 'COMPLETED',
      });

      expect(incompleta.completada, isFalse);
      expect(incompleta.estado, 'EN_CURSO');
      expect(completa.completada, isTrue);
    },
  );
}
