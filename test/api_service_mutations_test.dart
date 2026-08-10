import 'dart:convert';

import 'package:club_lectura_app/models/auth_session.dart';
import 'package:club_lectura_app/models/catalog_book.dart';
import 'package:club_lectura_app/services/api_service.dart';
import 'package:club_lectura_app/services/auth_session_service.dart';
import 'package:club_lectura_app/services/authenticated_http_client.dart';
import 'package:club_lectura_app/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final session = AuthSessionService.instance;
  late _MemoryTokenStorage storage;

  setUp(() async {
    storage = _MemoryTokenStorage();
    session.configureStorage(storage);
    await session.initialize();
    await session.establish(_session());
  });

  ApiService apiExpecting(
    String action,
    Map<String, dynamic> expectedBody, {
    Object responseBody = 'ok',
  }) {
    final inner = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.queryParameters, {'action': action});
      expect(request.headers['content-type'], startsWith('application/json'));
      expect(request.headers['authorization'], 'Bearer access-test');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body, expectedBody);
      expect(body, isNot(contains('usuario')));
      return http.Response(
        responseBody is String ? responseBody : jsonEncode(responseBody),
        200,
      );
    });
    return ApiService(
      client: AuthenticatedHttpClient(inner: inner, session: session),
    );
  }

  test('añadir un libro usa POST JSON y la identidad del token', () async {
    final result =
        await apiExpecting(
          'anadirLibroExistente',
          {'libro': 'book-1', 'prioridad': 'ALTA', 'formato': 'FISICO'},
          responseBody: {'ok': true, 'mensaje': 'Añadido'},
        ).anadirLibroExistente(
          usuario: 'nombre-que-no-se-envia',
          libro: 'book-1',
          prioridad: 'ALTA',
          formato: 'FISICO',
        );

    expect(result['ok'], isTrue);
  });

  test(
    'los estados y formatos visibles se serializan sin traducirlos',
    () async {
      await apiExpecting('actualizarEstado', {
        'libro': 'book-1',
        'estado': 'PENDIENTE',
        'valoracion': '',
        'reflexion': '',
        'motivoPausa': '',
        'fechaInicio': '',
        'fechaFin': '',
        'formato': 'AUDIOLIBRO',
      }).actualizarEstado(
        usuario: 'nombre-que-no-se-envia',
        libro: 'book-1',
        estado: 'PENDIENTE',
        formato: 'AUDIOLIBRO',
      );

      await apiExpecting('actualizarPreferenciasLibro', {
        'libro': 'book-1',
        'prioridad': 'MEDIA',
        'formato': 'AUDIOLIBRO',
      }).actualizarPreferenciasLibro(
        libro: 'book-1',
        prioridad: 'MEDIA',
        formato: 'AUDIOLIBRO',
      );
    },
  );

  test(
    'importar audiolibro conserva el vocabulario Flutter en el JSON',
    () async {
      const book = CatalogBook(
        id: 'google-1',
        source: 'GOOGLE',
        title: 'Libro de prueba',
        authors: ['Autora de prueba'],
        coverUrl: '',
        genre: 'Ficción',
        isbn: '',
        inMyLibrary: false,
        status: '',
        pages: 320,
        publicationYear: 2026,
      );
      await apiExpecting(
        'importarLibroCatalogo',
        {
          'prioridad': 'MEDIA',
          'formato': 'AUDIOLIBRO',
          'estado': 'PENDIENTE',
          'id': 'google-1',
          'origen': 'GOOGLE',
          'titulo': 'Libro de prueba',
          'autores': ['Autora de prueba'],
          'coverUrl': '',
          'genero': 'Ficción',
          'isbn': '',
          'paginas': 320,
          'anioPublicacion': 2026,
        },
        responseBody: {'ok': true},
      ).importarLibroCatalogo(
        book: book,
        prioridad: 'MEDIA',
        formato: 'AUDIOLIBRO',
        estado: 'PENDIENTE',
      );
    },
  );

  test('finalizar conserva el formato elegido en el cuerpo', () async {
    await apiExpecting('actualizarEstado', {
      'libro': 'book-1',
      'estado': 'FINALIZADO',
      'valoracion': '4.5',
      'reflexion': '',
      'motivoPausa': '',
      'fechaInicio': '2026-08-01',
      'fechaFin': '2026-08-09',
      'formato': 'AUDIOLIBRO',
    }).actualizarEstado(
      usuario: 'nombre-que-no-se-envia',
      libro: 'book-1',
      estado: 'FINALIZADO',
      valoracion: '4.5',
      fechaInicio: '2026-08-01',
      fechaFin: '2026-08-09',
      formato: 'AUDIOLIBRO',
    );
  });

  test('cambiar estado usa POST JSON', () async {
    final ok =
        await apiExpecting('actualizarEstado', {
          'libro': 'book-1',
          'estado': 'LEYENDO',
          'valoracion': '',
          'reflexion': '',
          'motivoPausa': '',
          'fechaInicio': '',
          'fechaFin': '',
          'formato': '',
        }).actualizarEstado(
          usuario: 'nombre-que-no-se-envia',
          libro: 'book-1',
          estado: 'LEYENDO',
        );

    expect(ok, isTrue);
  });

  test('cambiar progreso usa POST JSON', () async {
    final ok =
        await apiExpecting('actualizarProgresoLectura', {
          'libro': 'book-1',
          'progreso': 42,
          'comentario': 'En marcha',
          'paginaActual': 126,
          'paginasTotales': 300,
        }).actualizarProgresoLectura(
          usuario: 'nombre-que-no-se-envia',
          libro: 'book-1',
          progreso: 42,
          comentario: 'En marcha',
          paginaActual: 126,
          paginasTotales: 300,
        );

    expect(ok, isTrue);
  });

  test('cambiar valoración usa un único POST JSON', () async {
    final ok =
        await apiExpecting('actualizarValoracion', {
          'libro': 'book-1',
          'valoracion': '4.5',
        }).actualizarValoracion(
          usuario: 'nombre-que-no-se-envia',
          libro: 'book-1',
          valoracion: '4.5',
        );

    expect(ok, isTrue);
  });

  test('iniciar lectura usa POST JSON sin identidad duplicada', () async {
    final ok = await apiExpecting('iniciarLectura', {
      'libro': 'book-1',
    }).iniciarLectura(usuario: 'nombre-que-no-se-envia', libro: 'book-1');
    expect(ok, isTrue);
  });

  test('crear y editar un comentario usan POST JSON', () async {
    final created =
        await apiExpecting(
          'guardarComentarioLectura',
          {
            'libro': 'book-1',
            'capitulo': '3',
            'comentario': 'Texto inicial',
            'tipo': 'COMMENT',
          },
          responseBody: {
            'ok': true,
            'comentario': {
              'id': 'comment-new',
              'libro': 'book-1',
              'capitulo': '3',
              'usuario': 'Ada',
              'avatarUrl': '',
              'fecha': '09/08/2026, 12:00:00',
              'comentario': 'Texto inicial',
              'tipo': 'COMMENT',
              'color': '',
              'likes': 0,
              'reacciones': {},
              'miReaccion': null,
              'miLike': false,
              'esMio': true,
              'editado': false,
              'eliminado': false,
              'respuestas': [],
            },
          },
        ).guardarComentarioLectura(
          libro: 'book-1',
          capitulo: '3',
          usuario: 'nombre-que-no-se-envia',
          comentario: 'Texto inicial',
        );
    expect(created.id, 'comment-new');
    expect(created.comentario, 'Texto inicial');
    expect(created.esMio, isTrue);

    final edited = await apiExpecting('editarComentario', {
      'id': 'comment-1',
      'comentario': 'Texto editado',
    }).editarComentario(comentarioId: 'comment-1', comentario: 'Texto editado');
    expect(edited, isTrue);
  });

  test('reaccionar y votar usan POST JSON', () async {
    final reaction = await apiExpecting(
      'toggleLikeComentario',
      {'id': 'comment-1', 'reaccion': 'LOVE'},
      responseBody: {'ok': true},
    ).toggleLikeComentario(comentarioId: 'comment-1', reaccion: 'LOVE');
    expect(reaction['ok'], isTrue);

    final voted =
        await apiExpecting(
          'enviarVotacion',
          {'v1': 'book-1', 'v2': 'book-2', 'v3': '', 'v4': '', 'v5': ''},
          responseBody: {'ok': true},
        ).enviarVotacion(
          usuario: 'nombre-que-no-se-envia',
          votos: ['book-1', 'book-2'],
        );
    expect(voted, isTrue);
  });

  test('respuestas y borrados usan exclusivamente POST JSON', () async {
    expect(
      await apiExpecting('responderComentario', {
        'comentarioId': 'comment-1',
        'respuesta': 'Respuesta',
      }).guardarRespuestaComentario(
        comentarioId: 'comment-1',
        usuario: 'nombre-que-no-se-envia',
        respuesta: 'Respuesta',
      ),
      isTrue,
    );
    expect(
      await apiExpecting('eliminarComentario', {
        'id': 'comment-1',
      }).eliminarComentario(comentarioId: 'comment-1'),
      isTrue,
    );
    expect(
      await apiExpecting('editarRespuesta', {
        'id': 'reply-1',
        'respuesta': 'Editada',
      }).editarRespuesta(respuestaId: 'reply-1', respuesta: 'Editada'),
      isTrue,
    );
    expect(
      await apiExpecting('eliminarRespuesta', {
        'id': 'reply-1',
      }).eliminarRespuesta(respuestaId: 'reply-1'),
      isTrue,
    );
  });

  test('registrar mood usa POST JSON', () async {
    expect(
      await apiExpecting('registrarMoodClub', {
        'mood': 'INSPIRADA',
      }).registrarMoodClub('INSPIRADA'),
      isTrue,
    );
  });
}

AuthSession _session() => const AuthSession(
  accessToken: 'access-test',
  refreshToken: 'refresh-test',
  user: AuthUser(id: 'user-1', nombre: 'Lectora', email: 'test@example.com'),
);

class _MemoryTokenStorage implements TokenStorage {
  AuthSession? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<AuthSession?> read() async => value;

  @override
  Future<void> replaceTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    value = AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: value!.user,
    );
  }

  @override
  Future<void> write(AuthSession session) async => value = session;
}
