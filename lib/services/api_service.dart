import 'dart:convert';

import 'package:club_lectura_app/models/lectura_activa.dart';
import 'package:club_lectura_app/models/lectura_compartida.dart';
import 'package:club_lectura_app/models/mi_voto.dart';
import 'package:club_lectura_app/models/notificacion.dart';
import 'package:club_lectura_app/utils/app_config.dart';
import 'package:http/http.dart' as http;
import '../models/dashboard.dart';
import '../models/libro.dart';
import '../models/libro_finalizado.dart';
import '../models/nuevo_libro.dart';
import '../models/libros_data.dart';
import '../models/ranking.dart';
import '../models/ranking_item.dart';
import '../models/clubvision.dart';
import '../models/historial_clubvision.dart';
import '../models/usuario.dart';
import 'authenticated_http_client.dart';
import '../models/como_votaron.dart';
import '../models/comentarios_capitulo.dart';
import '../models/configuracion_lectura.dart';
import '../models/conversacion_libro.dart';
import '../models/perfil_usuario.dart';
import '../models/mood_club.dart';
import '../models/tendencias_club.dart';
import '../models/atmosfera_club.dart';
import '../models/catalog_book.dart';
import '../models/goodreads_import.dart';
import 'api_exception.dart';

class ApiService {
  static String get baseUrl => AppConfig.baseUrl;
  static final http.Client _client = AuthenticatedHttpClient();

  bool _respuestaOk(http.Response response) {
    if (response.statusCode != 200 && response.statusCode != 302) {
      return false;
    }

    final body = response.body.trim();

    if (body.toLowerCase() == 'ok') {
      return true;
    }

    dynamic json;

    try {
      json = jsonDecode(body);
    } catch (_) {
      return false;
    }

    if (json is Map<String, dynamic>) {
      return json["ok"] == true;
    }

    return false;
  }

  Future<List<Usuario>> getUsuarios() async {
    final response = await _client.get(Uri.parse('$baseUrl?action=usuarios'));
    final List data = jsonDecode(response.body);

    return data.map((e) => Usuario.fromJson(e)).toList();
  }

  Future<Dashboard> getDashboard() async {
    final response = await _client.get(Uri.parse('$baseUrl?action=dashboard'));

    if (response.statusCode == 200) {
      return Dashboard.fromJson(jsonDecode(response.body));
    }

    throw Exception('Error cargando dashboard');
  }

  Future<List<Libro>> getLibros() async {
    final response = await _client.get(Uri.parse('$baseUrl?action=libros'));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data.map((e) => Libro.fromJson(e)).toList();
    }

    throw Exception('Error cargando libros');
  }

  Future<List<CatalogBook>> getCatalogoGeneral({String query = ''}) async {
    final response = await _client.get(
      Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': query.trim().isEmpty
              ? 'catalogoGeneral'
              : 'buscarCatalogoGeneral',
          if (query.trim().isNotEmpty) 'q': query.trim(),
        },
      ),
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final decoded = jsonDecode(response.body);
    final items = decoded is Map<String, dynamic>
        ? decoded['libros'] as List<dynamic>? ?? const []
        : const <dynamic>[];
    return items
        .map(
          (item) =>
              CatalogBook.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  Future<void> importarLibroCatalogo({
    required CatalogBook book,
    required String prioridad,
    required String formato,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=importarLibroCatalogo'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': book.id,
        'origen': book.source,
        'titulo': book.title,
        'autores': book.authors,
        'coverUrl': book.coverUrl,
        'genero': book.genre,
        'isbn': book.isbn,
        'paginas': book.pages,
        'anioPublicacion': book.publicationYear,
        'prioridad': prioridad,
        'formato': formato,
      }),
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded is Map<String, dynamic>
            ? decoded['mensaje']?.toString() ?? 'No se pudo añadir el libro.'
            : 'No se pudo añadir el libro.',
      );
    }
  }

  Future<GoodreadsImportPreview> previsualizarImportacionGoodreads(
    List<GoodreadsImportRow> books,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=previsualizarImportacionGoodreads'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'libros': books.map((book) => book.toJson()).toList()}),
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded is Map<String, dynamic>
            ? decoded['mensaje']?.toString() ?? 'No se pudo revisar el archivo.'
            : 'No se pudo revisar el archivo.',
      );
    }
    return GoodreadsImportPreview.fromJson(decoded);
  }

  Future<GoodreadsImportSummary> confirmarImportacionGoodreads(
    List<GoodreadsImportRow> books,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=confirmarImportacionGoodreads'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'libros': books.map((book) => book.toJson()).toList()}),
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded is Map<String, dynamic>
            ? decoded['mensaje']?.toString() ??
                  'No se pudo importar el archivo.'
            : 'No se pudo importar el archivo.',
      );
    }
    final summary = decoded['resumen'];
    return GoodreadsImportSummary.fromJson(
      summary is Map<String, dynamic> ? summary : const {},
    );
  }

  Future<String> vincularVolumenSaga({
    required String sagaId,
    required String numero,
    required CatalogBook book,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=vincularVolumenSaga'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sagaId': sagaId,
        'numero': numero,
        'id': book.id,
        'origen': book.source,
        'titulo': book.title,
        'autores': book.authors,
        'coverUrl': book.coverUrl,
        'genero': book.genre,
        'isbn': book.isbn,
        'paginas': book.pages,
        'anioPublicacion': book.publicationYear,
      }),
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded is Map<String, dynamic>
            ? decoded['mensaje']?.toString() ?? 'No se pudo completar la saga.'
            : 'No se pudo completar la saga.',
      );
    }
    final linkedBook = decoded['libro'];
    if (linkedBook is Map &&
        linkedBook['id']?.toString().trim().isNotEmpty == true) {
      return linkedBook['id'].toString();
    }
    throw const ApiException(
      statusCode: 500,
      message: 'El servidor no confirmó el volumen añadido.',
    );
  }

  Future<void> actualizarNumeroVolumenSaga({
    required String bookId,
    required String numero,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=actualizarNumeroVolumenSaga'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'bookId': bookId, 'numero': numero}),
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded is Map<String, dynamic>
            ? decoded['mensaje']?.toString() ?? 'No se pudo cambiar el número.'
            : 'No se pudo cambiar el número.',
      );
    }
  }

  Future<void> actualizarEstadoEditorialSaga({
    required String sagaId,
    required String estadoEditorial,
    int? totalPrevisto,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=actualizarEstadoEditorialSaga'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sagaId': sagaId,
        'estadoEditorial': estadoEditorial,
        'totalPrevisto': totalPrevisto,
      }),
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded is Map<String, dynamic>
            ? decoded['mensaje']?.toString() ?? 'No se pudo actualizar la saga.'
            : 'No se pudo actualizar la saga.',
      );
    }
  }

  Future<List<LibroFinalizado>> getLibrosFinalizados() async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=librosFinalizados'),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data
          .map((e) => LibroFinalizado.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Error cargando finalizados');
  }

  Future<bool> iniciarLectura({
    required String usuario,
    required String libro,
  }) async {
    final uri = Uri.parse(
      baseUrl,
    ).replace(queryParameters: {"action": "iniciarLectura", "libro": libro});

    final response = await _client.get(uri);

    return _respuestaOk(response);
  }

  Future<bool> actualizarProgresoLectura({
    required String usuario,
    required String libro,
    required int progreso,
    required String comentario,
    int? paginaActual,
    int? paginasTotales,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=actualizarProgresoLectura'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'libro': libro,
        'progreso': progreso,
        'comentario': comentario,
        'paginaActual': ?paginaActual,
        'paginasTotales': ?paginasTotales,
      }),
    );
    return _respuestaOk(response);
  }

  Future<Map<String, dynamic>> toggleProgressReaction({
    required String libraryId,
    required String reaccion,
  }) async {
    final response = await _client.post(
      Uri.parse(
        baseUrl,
      ).replace(queryParameters: {'action': 'toggleProgressReaction'}),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'libraryId': libraryId, 'reaccion': reaccion}),
    );
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      return {'ok': false};
    }
    return data;
  }

  Future<LecturaCompartida> getLecturaCompartida() async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=lecturaCompartida'),
    );

    if (response.statusCode != 200) {
      throw Exception("Error cargando lectura compartida");
    }

    final json = jsonDecode(response.body);

    if (json["ok"] != true) {
      throw Exception("No existe lectura compartida");
    }

    return LecturaCompartida.fromJson(json);
  }

  Future<ComentariosCapitulo> getComentariosCapitulo({
    required String libro,
    required String capitulo,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'action': 'comentariosLectura',
        'libro': libro,
        'capitulo': capitulo,
      },
    );

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Error cargando comentarios');
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Respuesta de comentarios no válida');
    }

    return ComentariosCapitulo.fromJson(data);
  }

  Future<bool> marcarConversacionVista({
    required String libro,
    required String capitulo,
    String? usuario,
  }) async {
    final uri = Uri.parse(
      baseUrl,
    ).replace(queryParameters: {'action': 'marcarConversacionVista'});

    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'libro': libro, 'capitulo': capitulo}),
    );

    return _respuestaOk(response);
  }

  Future<void> guardarComentarioLectura({
    required String libro,
    required String capitulo,
    required String usuario,
    required String comentario,
    String tipo = 'COMMENT',
    String color = '',
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'action': 'guardarComentarioLectura',
        'libro': libro,
        'capitulo': capitulo,
        'comentario': comentario,
        'tipo': tipo,
        if (color.trim().isNotEmpty) 'color': color,
      },
    );
    await _client.get(uri);
  }

  Future<bool> guardarRespuestaComentario({
    required String comentarioId,
    required String usuario,
    required String respuesta,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        "action": "responderComentario",
        "comentarioId": comentarioId,
        "respuesta": respuesta,
      },
    );

    final response = await _client.get(uri);

    return _respuestaOk(response);
  }

  Future<bool> editarComentario({
    required String comentarioId,
    required String comentario,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        "action": "editarComentario",
        "id": comentarioId,
        "comentario": comentario,
      },
    );

    final response = await _client.get(uri);

    return _respuestaOk(response);
  }

  Future<bool> eliminarComentario({required String comentarioId}) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {"action": "eliminarComentario", "id": comentarioId},
    );

    final response = await _client.get(uri);

    return _respuestaOk(response);
  }

  Future<bool> editarRespuesta({
    required String respuestaId,
    required String respuesta,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        "action": "editarRespuesta",
        "id": respuestaId,
        "respuesta": respuesta,
      },
    );

    final response = await _client.get(uri);

    return _respuestaOk(response);
  }

  Future<bool> eliminarRespuesta({required String respuestaId}) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {"action": "eliminarRespuesta", "id": respuestaId},
    );

    final response = await _client.get(uri);

    return _respuestaOk(response);
  }

  Future<List<LecturaActiva>> getLecturasActivas() async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'action': 'lecturasActivas',
        '_refresh': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    final response = await _client.get(
      uri,
      headers: const {'Cache-Control': 'no-cache'},
    );

    if (response.statusCode != 200) {
      throw Exception("Error cargando lecturas");
    }

    final List lista = jsonDecode(response.body);

    return lista.map((e) => LecturaActiva.fromJson(e)).toList();
  }

  Future<bool> crearLectura({
    required String libro,
    required int capitulos,
    required bool prologo,
    required bool epilogo,
    int? paginas,
    String tipo = "LIBRE",
  }) async {
    final response = await _client.get(
      Uri.parse(
        '$baseUrl?action=crearLectura'
        '&libro=${Uri.encodeComponent(libro)}'
        '&capitulos=$capitulos'
        '&prologo=${prologo ? 1 : 0}'
        '&epilogo=${epilogo ? 1 : 0}'
        '${paginas == null ? '' : '&paginas=$paginas'}'
        '&tipo=$tipo',
      ),
    );

    return _respuestaOk(response);
  }

  Future<ConfiguracionLectura> getConfiguracionLectura({
    required String libro,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {'action': 'configuracionLectura', 'libro': libro},
    );

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Error cargando la configuración de lectura');
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Respuesta de configuración no válida');
    }

    return ConfiguracionLectura.fromJson(data);
  }

  Future<List<ConversacionLibro>> getConversacionesLibro({
    required String libro,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {"action": "conversacionesLibro", "libro": libro},
    );

    final response = await _client.get(uri);

    final json = jsonDecode(response.body) as List;

    return json.map((e) => ConversacionLibro.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> crearLibro(NuevoLibro libro) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=crearLibro'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(libro.toJson()),
    );

    if (response.statusCode != 200) {
      return {
        'ok': false,
        'mensaje': 'No se ha podido conectar con el servidor.',
      };
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      return {
        'ok': false,
        'mensaje': 'La respuesta del servidor no es válida.',
      };
    }

    return data;
  }

  Future<Map<String, dynamic>> editarLibro(NuevoLibro libro) async {
    if (libro.bookId == null || libro.bookId!.trim().isEmpty) {
      return {'ok': false, 'mensaje': 'Falta el identificador del libro.'};
    }

    final response = await _client.post(
      Uri.parse('$baseUrl?action=editarLibro'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(libro.toJson()),
    );

    if (response.statusCode != 200) {
      return {
        'ok': false,
        'mensaje': 'No se ha podido conectar con el servidor.',
      };
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      return {
        'ok': false,
        'mensaje': 'La respuesta del servidor no es válida.',
      };
    }

    return data;
  }

  Future<List<ComoVotaron>> getComoVotaron() async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=comoVotaron'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      final votos = json
          .whereType<Map<String, dynamic>>()
          .map(ComoVotaron.fromJson)
          .toList();

      try {
        final portadas = await _indiceVisualLibros();
        return votos
            .map(
              (persona) => ComoVotaron(
                usuaria: persona.usuaria,
                avatarUrl: persona.avatarUrl,
                votos: persona.votos.map((voto) {
                  final visual = portadas[_normalizarTitulo(voto.libro)];
                  return voto.copyWith(
                    bookId: voto.bookId.isNotEmpty ? voto.bookId : visual?.$1,
                    coverUrl: voto.coverUrl.isNotEmpty
                        ? voto.coverUrl
                        : visual?.$2,
                  );
                }).toList(),
              ),
            )
            .toList();
      } catch (_) {
        return votos;
      }
    }

    throw Exception('Error cargando las votaciones');
  }

  Future<bool> actualizarEstado({
    required String usuario,
    required String libro,
    required String estado,
    String? valoracion,
    String? reflexion,
    String? motivoPausa,
    String? fechaInicio,
    String? fechaFin,
    String? formato,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=actualizarEstado'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'libro': libro,
        'estado': estado,
        'valoracion': valoracion ?? '',
        'reflexion': reflexion ?? '',
        'motivoPausa': motivoPausa ?? '',
        'fechaInicio': fechaInicio ?? '',
        'fechaFin': fechaFin ?? '',
        'formato': formato ?? '',
      }),
    );

    if (response.statusCode == 302) {
      return true;
    }

    return _respuestaOk(response);
  }

  Future<bool> actualizarValoracion({
    required String usuario,
    required String libro,
    required String valoracion,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        "action": "actualizarValoracion",
        "libro": libro,
        "valoracion": valoracion,
      },
    );

    final response = await _client.get(uri);

    if (_respuestaOk(response)) {
      return true;
    }

    final postResponse = await _client.post(
      Uri.parse('$baseUrl?action=actualizarValoracion'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'libro': libro, 'valoracion': valoracion}),
    );

    return _respuestaOk(postResponse);
  }

  Future<LibrosData> getLibrosData() async {
    final librosFuture = getLibros();
    final finalizadosFuture = getLibrosFinalizados();
    final libros = await librosFuture;
    final finalizados = await finalizadosFuture;

    return LibrosData(libros: libros, finalizados: finalizados);
  }

  Future<Ranking> getRanking({int? anio}) async {
    final year = anio ?? DateTime.now().year;
    final uri = Uri.parse(
      baseUrl,
    ).replace(queryParameters: {'action': 'ranking', 'anio': '$year'});
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      return Ranking.fromJson(jsonDecode(response.body));
    }

    throw Exception('Error cargando ranking');
  }

  Future<List<RankingItem>> getTopLectorasMes({DateTime? fecha}) async {
    final mesActual = fecha ?? DateTime.now();
    final usuarios = await getUsuarios();

    final resultados = await Future.wait(
      usuarios.map((usuario) async {
        try {
          final perfil = await getPerfilUsuario(usuario.nombre);
          final total = perfil.terminados.where((libro) {
            final partes = libro.fecha.trim().split('/');

            if (partes.length != 3) return false;

            final mes = int.tryParse(partes[1]);
            final anio = int.tryParse(partes[2]);

            return mes == mesActual.month && anio == mesActual.year;
          }).length;

          return RankingItem(
            nombre: usuario.nombre,
            total: total,
            avatarUrl: perfil.avatarUrl,
          );
        } catch (_) {
          return RankingItem(nombre: usuario.nombre, avatarUrl: '');
        }
      }),
    );

    final lectoras = resultados.where((item) => item.total > 0).toList()
      ..sort((a, b) {
        final porTotal = b.total.compareTo(a.total);

        if (porTotal != 0) return porTotal;

        return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
      });

    return lectoras.take(3).toList(growable: false);
  }

  Future<ClubvisionData> getClubvision() async {
    final response = await _client.get(Uri.parse('$baseUrl?action=clubvision'));

    if (response.statusCode == 200) {
      return ClubvisionData.fromJson(jsonDecode(response.body));
    }

    throw Exception('Error cargando Clubvisión');
  }

  Future<List<HistorialClubvision>> getHistorialClubvision() async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=historialClubvision'),
    );

    final List data = jsonDecode(response.body);

    final historial = data
        .whereType<Map<String, dynamic>>()
        .map(HistorialClubvision.fromJson)
        .toList();

    try {
      final portadas = await _indiceVisualLibros();
      return historial.map((edicion) {
        final ganadora = portadas[_normalizarTitulo(edicion.ganadora)];
        final segunda = portadas[_normalizarTitulo(edicion.segunda)];
        final tercera = portadas[_normalizarTitulo(edicion.tercera)];
        return edicion.copyWith(
          ganadoraBookId: edicion.ganadoraBookId.isNotEmpty
              ? edicion.ganadoraBookId
              : ganadora?.$1,
          ganadoraCoverUrl: edicion.ganadoraCoverUrl.isNotEmpty
              ? edicion.ganadoraCoverUrl
              : ganadora?.$2,
          segundaBookId: edicion.segundaBookId.isNotEmpty
              ? edicion.segundaBookId
              : segunda?.$1,
          segundaCoverUrl: edicion.segundaCoverUrl.isNotEmpty
              ? edicion.segundaCoverUrl
              : segunda?.$2,
          terceraBookId: edicion.terceraBookId.isNotEmpty
              ? edicion.terceraBookId
              : tercera?.$1,
          terceraCoverUrl: edicion.terceraCoverUrl.isNotEmpty
              ? edicion.terceraCoverUrl
              : tercera?.$2,
        );
      }).toList();
    } catch (_) {
      return historial;
    }
  }

  Future<Map<String, (String, String)>> _indiceVisualLibros() async {
    final data = await getLibrosData();
    final resultado = <String, (String, String)>{};

    for (final libro in data.libros) {
      final clave = _normalizarTitulo(libro.libro);
      if (clave.isNotEmpty &&
          (!resultado.containsKey(clave) || libro.coverUrl.isNotEmpty)) {
        resultado[clave] = (libro.bookId, libro.coverUrl);
      }
    }
    for (final libro in data.finalizados) {
      final clave = _normalizarTitulo(libro.libro);
      if (clave.isNotEmpty &&
          (!resultado.containsKey(clave) || libro.coverUrl.isNotEmpty)) {
        resultado[clave] = (libro.bookId, libro.coverUrl);
      }
    }
    return resultado;
  }

  String _normalizarTitulo(String value) => value.trim().toLowerCase();

  Future<Map<String, dynamic>> anadirLibroExistente({
    required String usuario,
    required String libro,
    required String prioridad,
    required String formato,
  }) async {
    final response = await _client.get(
      Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'anadirLibroExistente',
          'libro': libro,
          'prioridad': prioridad,
          'formato': formato,
        },
      ),
    );

    if (response.statusCode != 200) {
      return {"ok": false, "mensaje": "Error de conexión con el servidor."};
    }

    final json = jsonDecode(response.body);

    return {
      "ok": json["ok"] == true,
      "mensaje": json["mensaje"] ?? "Ha ocurrido un error.",
    };
  }

  Future<bool> actualizarPreferenciasLibro({
    required String libro,
    required String prioridad,
    required String formato,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=actualizarPreferenciasLibro'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'libro': libro,
        'prioridad': prioridad,
        'formato': formato,
      }),
    );
    return _respuestaOk(response);
  }

  Future<MiVoto> getMiVoto(String usuario) async {
    final response = await _client.get(Uri.parse('$baseUrl?action=miVoto'));

    if (response.statusCode == 200) {
      return MiVoto.fromJson(jsonDecode(response.body));
    }

    throw Exception('Error cargando mi voto');
  }

  Future<bool> enviarVotacion({
    required String usuario,
    required List<String> votos,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'action': 'enviarVotacion',
        'v1': votos.isNotEmpty ? votos[0] : '',
        'v2': votos.length > 1 ? votos[1] : '',
        'v3': votos.length > 2 ? votos[2] : '',
        'v4': votos.length > 3 ? votos[3] : '',
        'v5': votos.length > 4 ? votos[4] : '',
      },
    );

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      return false;
    }

    final json = jsonDecode(response.body);

    return json["ok"] == true;
  }

  Future<Map<String, dynamic>> toggleLikeComentario({
    required String comentarioId,
    String reaccion = 'LIKE',
  }) async {
    final response = await _client.get(
      Uri.parse(
        '$baseUrl?action=toggleLikeComentario'
        '&id=${Uri.encodeComponent(comentarioId)}'
        '&reaccion=${Uri.encodeComponent(reaccion)}',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception("Error dando like");
    }

    return jsonDecode(response.body);
  }

  Future<PerfilUsuario> getPerfilUsuario(String usuario) async {
    final uri = Uri.parse(
      baseUrl,
    ).replace(queryParameters: {'action': 'perfilUsuario', 'perfil': usuario});

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Error cargando perfil');
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Respuesta de perfil no válida');
    }

    if (data['ok'] == false) {
      throw Exception(
        data['mensaje']?.toString() ?? 'No se pudo cargar el perfil',
      );
    }

    return PerfilUsuario.fromJson(data);
  }

  Future<Map<String, dynamic>> actualizarFechasLectura({
    required String usuario,
    required String libraryId,
    String? completionId,
    required String fechaInicio,
    required String fechaFin,
    String? valoracion,
    String? resena,
  }) async {
    final body = <String, dynamic>{
      'libraryId': libraryId,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
    };
    if (completionId != null && completionId.isNotEmpty) {
      body['completionId'] = completionId;
    }
    if (valoracion != null) body['valoracion'] = valoracion;
    if (resena != null) body['resena'] = resena;

    final response = await _client.post(
      Uri.parse('$baseUrl?action=actualizarFechasLectura'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      return {
        'ok': false,
        'mensaje': 'No se ha podido conectar con el servidor.',
      };
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      return {
        'ok': false,
        'mensaje': 'La respuesta del servidor no es válida.',
      };
    }

    return data;
  }

  Future<Map<String, dynamic>> actualizarAvatarPerfil({
    required String usuario,
    required String avatarUrl,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=actualizarAvatarPerfil'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'avatarUrl': avatarUrl}),
    );

    if (response.statusCode != 200) {
      return {
        'ok': false,
        'mensaje': 'No se ha podido conectar con el servidor.',
      };
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      return {
        'ok': false,
        'mensaje': 'La respuesta del servidor no es válida.',
      };
    }

    return data;
  }

  Future<MoodClub> getMoodClub() async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'action': 'moodClub',
        '_refresh': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      return MoodClub.fromJson(jsonDecode(response.body));
    }

    throw Exception('Error cargando el mood del club');
  }

  Future<bool> registrarMoodClub(String mood) async {
    final uri = Uri.parse(
      baseUrl,
    ).replace(queryParameters: {'action': 'registrarMoodClub', 'mood': mood});
    return _respuestaOk(await _client.get(uri));
  }

  Future<TendenciasClub> getTendenciasClub() async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=tendenciasClub'),
    );

    if (response.statusCode == 200) {
      return TendenciasClub.fromJson(jsonDecode(response.body));
    }

    throw Exception('Error cargando tendencias');
  }

  Future<AtmosferaClub> getAtmosferaClub() async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=atmosferaClub'),
    );

    if (response.statusCode == 200) {
      return AtmosferaClub.fromJson(jsonDecode(response.body));
    }

    throw Exception('Error cargando las atmósferas del club');
  }

  Future<Map<String, dynamic>> quitarLibroPendientes({
    required String usuario,
    required String libro,
  }) async {
    final uri = Uri.parse(
      baseUrl,
    ).replace(queryParameters: {'action': 'quitarLibroPendientes'});

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'libro': libro}),
    );

    if (response.statusCode != 200) {
      return {
        'ok': false,
        'mensaje': 'No se ha podido conectar con el servidor.',
      };
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      return {
        'ok': false,
        'mensaje': 'La respuesta del servidor no es válida.',
      };
    }

    return data;
  }

  Future<Map<String, dynamic>> getLibrosPorAutor(String autorId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=librosPorAutor&autorId=$autorId'),
    );
    if (response.statusCode != 200) return {};
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) return {};
    return data;
  }

  Future<NotificacionesData> getNotificaciones() async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=notificaciones'),
    );
    if (response.statusCode != 200) {
      return const NotificacionesData(notificaciones: [], noLeidas: 0);
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      return const NotificacionesData(notificaciones: [], noLeidas: 0);
    }
    return NotificacionesData.fromJson(data);
  }

  Future<void> marcarNotificacionLeida(String id) async {
    await _client.post(
      Uri.parse('$baseUrl?action=marcarLeida'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id}),
    );
  }

  Future<void> marcarTodasNotificacionesLeidas() async {
    await _client.post(
      Uri.parse('$baseUrl?action=marcarTodasLeidas'),
      headers: const {'Content-Type': 'application/json'},
      body: '{}',
    );
  }

  Future<void> eliminarNotificacion(String id) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=eliminarNotificacion'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id}),
    );
    if (!_respuestaOk(response)) {
      throw ApiException.fromResponse(response);
    }
  }

  Future<Map<String, dynamic>> getAfinidadDetalle(String miembroId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=afinidadDetalle&miembroId=$miembroId'),
    );
    if (response.statusCode != 200) return {};
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) return {};
    return data;
  }

  Future<void> setSeriesOverride({
    required String seriesId,
    required int posicion,
    required String tipo, // 'LEIDO_EXTERNO' o 'OMITIDO'
  }) async {
    await _client.post(
      Uri.parse('$baseUrl?action=setSeriesOverride'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'seriesId': seriesId,
        'posicion': posicion,
        'tipo': tipo,
      }),
    );
  }

  Future<void> removeSeriesOverride({
    required String seriesId,
    required int posicion,
  }) async {
    await _client.post(
      Uri.parse('$baseUrl?action=removeSeriesOverride'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'seriesId': seriesId, 'posicion': posicion}),
    );
  }
}
