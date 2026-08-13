import 'dart:convert';

import 'package:club_lectura_app/models/lectura_activa.dart';
import 'package:club_lectura_app/models/mi_voto.dart';
import 'package:club_lectura_app/models/notificacion.dart';
import 'package:club_lectura_app/services/libros_data_cache.dart';
import 'package:club_lectura_app/utils/app_config.dart';
import 'package:http/http.dart' as http;
import '../models/achievements/achievement.dart';
import '../models/dashboard.dart';
import '../models/libro.dart';
import '../models/libro_finalizado.dart';
import '../models/nuevo_libro.dart';
import '../models/libros_data.dart';
import '../models/ranking.dart';
import '../models/clubvision.dart';
import '../models/historial_clubvision.dart';
import '../models/usuario.dart';
import 'authenticated_http_client.dart';
import '../models/como_votaron.dart';
import '../models/comentarios_capitulo.dart';
import '../models/comentario_lectura.dart';
import '../models/configuracion_lectura.dart';
import '../models/conversacion_libro.dart';
import '../models/perfil_usuario.dart';
import '../models/mood_club.dart';
import '../models/tendencias_club.dart';
import '../models/catalog_book.dart';
import '../models/goodreads_import.dart';
import '../models/saga_oculta.dart';
import '../models/cursor_page.dart';
import 'api_exception.dart';
import 'http_response_handler.dart';

class ApiService {
  ApiService({http.Client? client})
    : _client = client ?? AuthenticatedHttpClient();

  static String get baseUrl => AppConfig.baseUrl;
  final http.Client _client;

  dynamic _decodeJson(http.Response response) =>
      HttpResponseHandler.decodeJson(response);

  Future<http.Response> _postJson(
    String action, [
    Map<String, dynamic> body = const {},
  ]) => _client.post(
    Uri.parse(baseUrl).replace(queryParameters: {'action': action}),
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

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
    final List data = _decodeJson(response);

    return data.map((e) => Usuario.fromJson(e)).toList();
  }

  Future<Dashboard> getDashboard() async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=dashboard'),
      headers: const {AuthenticatedHttpClient.noRetryHeader: 'true'},
    );

    if (response.statusCode == 200) {
      return Dashboard.fromJson(_decodeJson(response));
    }

    throw Exception('Error cargando dashboard');
  }

  Future<List<Libro>> getLibros() async {
    final response = await _client.get(Uri.parse('$baseUrl?action=libros'));

    if (response.statusCode == 200) {
      final List data = _decodeJson(response);

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
    final decoded = _decodeJson(response);
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

  Future<CursorPage<CatalogBook>> getCatalogoGeneralPage({
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _client.get(
      Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'catalogoGeneral',
          'limit': '$limit',
          if (cursor?.isNotEmpty == true) 'cursor': cursor!,
        },
      ),
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    final decoded = _decodeJson(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 500,
        message: 'La respuesta del catálogo no es válida.',
      );
    }
    return CursorPage.fromJson(decoded, CatalogBook.fromJson);
  }

  // REEMPLAZA el método completo:
  Future<void> importarLibroCatalogo({
    CatalogBook? book,
    String? bookId,
    required String prioridad,
    required String formato,
    String? estado,
    String? fechaInicio,
    String? fechaFin,
    String? valoracion,
  }) async {
    final body = <String, dynamic>{
      'prioridad': prioridad,
      if (formato.trim().isNotEmpty) 'formato': formato,
      if (estado != null && estado.isNotEmpty) 'estado': estado,
      if (fechaInicio != null && fechaInicio.isNotEmpty)
        'fechaInicio': fechaInicio,
      if (fechaFin != null && fechaFin.isNotEmpty) 'fechaFin': fechaFin,
      if (valoracion != null && valoracion.isNotEmpty) 'valoracion': valoracion,
    };

    if (book != null) {
      body.addAll({
        'id': book.id,
        'origen': book.source,
        'titulo': book.title,
        'autores': book.authors,
        'coverUrl': book.coverUrl,
        'genero': book.genre,
        'isbn': book.isbn,
        'paginas': book.pages,
        'anioPublicacion': book.publicationYear,
      });
    } else if (bookId != null) {
      body['id'] = bookId;
      body['origen'] = 'CLUBREADS';
    }

    final response = await _client.post(
      Uri.parse('$baseUrl?action=importarLibroCatalogo'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    final decoded = _decodeJson(response);
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
      headers: const {
        'Content-Type': 'application/json',
        AuthenticatedHttpClient.longTimeoutHeader: 'true',
      },
      body: jsonEncode({'libros': books.map((book) => book.toJson()).toList()}),
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final decoded = _decodeJson(response);
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
    List<GoodreadsImportRow> books, {
    Map<int, String> resolutions = const {},
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=confirmarImportacionGoodreads'),
      headers: const {
        'Content-Type': 'application/json',
        AuthenticatedHttpClient.longTimeoutHeader: 'true',
      },
      body: jsonEncode({
        'libros': books.map((book) => book.toJson()).toList(),
        if (resolutions.isNotEmpty)
          'resoluciones': resolutions.entries
              .map((entry) => {'index': entry.key, 'bookId': entry.value})
              .toList(growable: false),
      }),
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final decoded = _decodeJson(response);
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
    String? estado,
    String? formato,
    String? valoracion,
    String? fechaInicio,
    String? fechaFin,
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
        if (estado?.trim().isNotEmpty == true) 'estado': estado!.trim(),
        if (formato?.trim().isNotEmpty == true) 'formato': formato!.trim(),
        if (valoracion?.trim().isNotEmpty == true)
          'valoracion': valoracion!.trim(),
        if (fechaInicio?.trim().isNotEmpty == true)
          'fechaInicio': fechaInicio!.trim(),
        if (fechaFin?.trim().isNotEmpty == true) 'fechaFin': fechaFin!.trim(),
      }),
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final decoded = _decodeJson(response);
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
    final decoded = _decodeJson(response);
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
    final decoded = _decodeJson(response);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded is Map<String, dynamic>
            ? decoded['mensaje']?.toString() ?? 'No se pudo actualizar la saga.'
            : 'No se pudo actualizar la saga.',
      );
    }
  }

  Future<void> ocultarSaga({required String sagaId}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=ocultarSaga'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'sagaId': sagaId}),
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final decoded = _decodeJson(response);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded is Map<String, dynamic>
            ? decoded['mensaje']?.toString() ?? 'No se pudo ocultar la saga.'
            : 'No se pudo ocultar la saga.',
      );
    }
  }

  Future<void> eliminarSaga({required String sagaId}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=eliminarSaga'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'sagaId': sagaId}),
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    final decoded = _decodeJson(response);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded is Map<String, dynamic>
            ? decoded['mensaje']?.toString() ?? 'No se pudo eliminar la saga.'
            : 'No se pudo eliminar la saga.',
      );
    }
  }

  Future<List<SagaOculta>> getSagasOcultas() async {
    final response = await _client.get(
      Uri.parse(baseUrl).replace(queryParameters: {'action': 'sagasOcultas'}),
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final decoded = _decodeJson(response);
    final items = decoded is Map<String, dynamic>
        ? decoded['sagas'] as List<dynamic>? ?? const []
        : decoded is List<dynamic>
        ? decoded
        : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) => SagaOculta.fromJson(Map<String, dynamic>.from(item)))
        .where((saga) => saga.id.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<void> mostrarSaga({required String sagaId}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=mostrarSaga'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'sagaId': sagaId}),
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final decoded = _decodeJson(response);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded is Map<String, dynamic>
            ? decoded['mensaje']?.toString() ?? 'No se pudo mostrar la saga.'
            : 'No se pudo mostrar la saga.',
      );
    }
  }

  Future<List<LibroFinalizado>> getLibrosFinalizados() async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=librosFinalizados'),
    );

    if (response.statusCode == 200) {
      final List data = _decodeJson(response);

      return data
          .map((e) => LibroFinalizado.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Error cargando finalizados');
  }

  Future<CursorPage<LibroFinalizado>> getLibrosFinalizadosPage({
    int limit = 50,
    String? cursor,
  }) async {
    final response = await _client.get(
      Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'librosFinalizados',
          'limit': '$limit',
          if (cursor?.isNotEmpty == true) 'cursor': cursor!,
        },
      ),
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    final decoded = _decodeJson(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 500,
        message: 'La respuesta de libros finalizados no es válida.',
      );
    }
    return CursorPage.fromJson(decoded, LibroFinalizado.fromJson);
  }

  Future<List<LibroFinalizado>> getAllLibrosFinalizados() async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=librosFinalizadosTodos'),
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    final List data = _decodeJson(response);
    return data
        .map((e) => LibroFinalizado.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> iniciarLectura({
    required String usuario,
    required String libro,
  }) async {
    final response = await _postJson('iniciarLectura', {'libro': libro});

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
    final data = _decodeJson(response);
    if (data is! Map<String, dynamic>) {
      return {'ok': false};
    }
    return data;
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

    final data = _decodeJson(response);

    if (data is! Map<String, dynamic>) {
      throw Exception('Respuesta de comentarios no válida');
    }

    return ComentariosCapitulo.fromJson(data);
  }

  Future<CursorPage<ComentarioLectura>> getComentariosCapituloPage({
    required String libro,
    required String capitulo,
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _client.get(
      Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'comentariosLectura',
          'libro': libro,
          'capitulo': capitulo,
          'limit': '$limit',
          if (cursor?.isNotEmpty == true) 'cursor': cursor!,
        },
      ),
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    final decoded = _decodeJson(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 500,
        message: 'La respuesta de comentarios no es válida.',
      );
    }
    return CursorPage.fromJson(decoded, ComentarioLectura.fromJson);
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

  Future<ComentarioLectura> guardarComentarioLectura({
    required String libro,
    required String capitulo,
    required String usuario,
    required String comentario,
    String tipo = 'COMMENT',
    String color = '',
  }) async {
    final response = await _postJson('guardarComentarioLectura', {
      'libro': libro,
      'capitulo': capitulo,
      'comentario': comentario,
      'tipo': tipo,
      if (color.trim().isNotEmpty) 'color': color,
    });
    final decoded = _decodeJson(response);
    if (decoded is! Map<String, dynamic> ||
        decoded['ok'] != true ||
        decoded['comentario'] is! Map) {
      throw const ApiException(
        statusCode: 500,
        message: 'No se ha podido confirmar el comentario publicado.',
      );
    }
    return ComentarioLectura.fromJson(
      Map<String, dynamic>.from(decoded['comentario'] as Map),
    );
  }

  Future<bool> guardarRespuestaComentario({
    required String comentarioId,
    required String usuario,
    required String respuesta,
  }) async {
    final response = await _postJson('responderComentario', {
      'comentarioId': comentarioId,
      'respuesta': respuesta,
    });

    return _respuestaOk(response);
  }

  Future<bool> editarComentario({
    required String comentarioId,
    required String comentario,
  }) async {
    final response = await _postJson('editarComentario', {
      'id': comentarioId,
      'comentario': comentario,
    });

    return _respuestaOk(response);
  }

  Future<bool> eliminarComentario({required String comentarioId}) async {
    final response = await _postJson('eliminarComentario', {
      'id': comentarioId,
    });

    return _respuestaOk(response);
  }

  Future<bool> editarRespuesta({
    required String respuestaId,
    required String respuesta,
  }) async {
    final response = await _postJson('editarRespuesta', {
      'id': respuestaId,
      'respuesta': respuesta,
    });

    return _respuestaOk(response);
  }

  Future<bool> eliminarRespuesta({required String respuestaId}) async {
    final response = await _postJson('eliminarRespuesta', {'id': respuestaId});

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

    final List lista = _decodeJson(response);

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
    final response = await _postJson('crearLectura', {
      'libro': libro,
      'capitulos': capitulos,
      'prologo': prologo ? 1 : 0,
      'epilogo': epilogo ? 1 : 0,
      'paginas': ?paginas,
      'tipo': tipo,
    });

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

    final data = _decodeJson(response);

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

    final json = _decodeJson(response) as List;

    return json.map((e) => ConversacionLibro.fromJson(e)).toList();
  }

  Future<CursorPage<ConversacionLibro>> getConversacionesLibroPage({
    required String libro,
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _client.get(
      Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'conversacionesLibro',
          'libro': libro,
          'limit': '$limit',
          if (cursor?.isNotEmpty == true) 'cursor': cursor!,
        },
      ),
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    final decoded = _decodeJson(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 500,
        message: 'La respuesta de conversaciones no es válida.',
      );
    }
    return CursorPage.fromJson(decoded, ConversacionLibro.fromJson);
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

    final data = _decodeJson(response);

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

    final data = _decodeJson(response);

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
      final List<dynamic> json = _decodeJson(response);
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
    final response = await _postJson('actualizarValoracion', {
      'libro': libro,
      'valoracion': valoracion,
    });
    return _respuestaOk(response);
  }

  Future<LibrosData> getLibrosData() {
    return LibrosDataCache.instance.get(() async {
      final libros = await getLibros();
      final finalizados = await getAllLibrosFinalizados();
      return LibrosData(
        libros: libros,
        finalizados: _deduplicarFinalizados(finalizados),
      );
    });
  }

  Future<Map<String, dynamic>> getLibroPorId(String bookId) async {
    final response = await _client.get(
      Uri.parse(
        baseUrl,
      ).replace(queryParameters: {'action': 'libroPorId', 'bookId': bookId}),
    );
    if (response.statusCode != 200) return {'ok': false};
    final data = _decodeJson(response);
    if (data is! Map<String, dynamic>) return {'ok': false};
    return data;
  }

  List<LibroFinalizado> _deduplicarFinalizados(
    List<LibroFinalizado> finalizados,
  ) {
    final resultado = <String, LibroFinalizado>{};
    for (final item in finalizados) {
      final normalizedTitle = _normalizarTitulo(item.libro);
      final bookKey = normalizedTitle.isNotEmpty
          ? normalizedTitle
          : item.bookId.trim().toLowerCase();
      final key = '$bookKey|${item.usuario.trim().toLowerCase()}';
      final anterior = resultado[key];
      if (anterior == null ||
          _riquezaFinalizado(item) > _riquezaFinalizado(anterior)) {
        resultado[key] = item;
      }
    }
    return resultado.values.toList(growable: false);
  }

  int _riquezaFinalizado(LibroFinalizado item) =>
      (item.coverUrl.trim().isNotEmpty ? 4 : 0) +
      (item.resena.trim().isNotEmpty ? 2 : 0) +
      (item.valoracion.trim().isNotEmpty ? 1 : 0);

  Future<Ranking> getRanking({int? anio}) async {
    final year = anio ?? DateTime.now().year;
    final uri = Uri.parse(
      baseUrl,
    ).replace(queryParameters: {'action': 'ranking', 'anio': '$year'});
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      return Ranking.fromJson(_decodeJson(response));
    }

    throw Exception('Error cargando ranking');
  }

  Future<ClubvisionData> getClubvision() async {
    final response = await _client.get(Uri.parse('$baseUrl?action=clubvision'));

    if (response.statusCode == 200) {
      return ClubvisionData.fromJson(_decodeJson(response));
    }

    throw Exception('Error cargando Clubvisión');
  }

  Future<List<HistorialClubvision>> getHistorialClubvision() async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=historialClubvision'),
    );

    final List data = _decodeJson(response);

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

  Future<CursorPage<HistorialClubvision>> getHistorialClubvisionPage({
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _client.get(
      Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'historialClubvision',
          'limit': '$limit',
          if (cursor?.isNotEmpty == true) 'cursor': cursor!,
        },
      ),
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    final decoded = _decodeJson(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 500,
        message: 'La respuesta del historial no es válida.',
      );
    }
    return CursorPage.fromJson(decoded, HistorialClubvision.fromJson);
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
    final response = await _postJson('anadirLibroExistente', {
      'libro': libro,
      'prioridad': prioridad,
      if (formato.trim().isNotEmpty) 'formato': formato,
    });

    if (response.statusCode != 200) {
      return {"ok": false, "mensaje": "Error de conexión con el servidor."};
    }

    final json = _decodeJson(response);

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
        if (prioridad.trim().isNotEmpty) 'prioridad': prioridad,
        if (formato.trim().isNotEmpty) 'formato': formato,
      }),
    );
    return _respuestaOk(response);
  }

  Future<MiVoto> getMiVoto(String usuario) async {
    final response = await _client.get(Uri.parse('$baseUrl?action=miVoto'));

    if (response.statusCode == 200) {
      return MiVoto.fromJson(_decodeJson(response));
    }

    throw Exception('Error cargando mi voto');
  }

  Future<bool> enviarVotacion({
    required String usuario,
    required List<String> votos,
  }) async {
    final response = await _postJson('enviarVotacion', {
      'v1': votos.isNotEmpty ? votos[0] : '',
      'v2': votos.length > 1 ? votos[1] : '',
      'v3': votos.length > 2 ? votos[2] : '',
      'v4': votos.length > 3 ? votos[3] : '',
      'v5': votos.length > 4 ? votos[4] : '',
    });

    if (response.statusCode != 200) {
      return false;
    }

    final json = _decodeJson(response);

    return json["ok"] == true;
  }

  Future<Map<String, dynamic>> toggleLikeComentario({
    required String comentarioId,
    String reaccion = 'LIKE',
  }) async {
    final response = await _postJson('toggleLikeComentario', {
      'id': comentarioId,
      'reaccion': reaccion,
    });

    if (response.statusCode != 200) {
      throw Exception("Error dando like");
    }

    return _decodeJson(response);
  }

  Future<PerfilUsuario> getPerfilUsuario(String usuario) async {
    final uri = Uri.parse(
      baseUrl,
    ).replace(queryParameters: {'action': 'perfilUsuario', 'perfil': usuario});

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Error cargando perfil');
    }

    final data = _decodeJson(response);

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

  Future<PerfilUsuario> getPerfilUsuarioCompleto(String usuario) async {
    final metadata = await getPerfilUsuario(usuario);
    final terminados = <PerfilLibroTerminado>[];
    String? cursor;
    do {
      final response = await _client.get(
        Uri.parse(baseUrl).replace(
          queryParameters: {
            'action': 'perfilUsuario',
            'perfil': usuario,
            'limit': '50',
            if (cursor?.isNotEmpty == true) 'cursor': cursor!,
          },
        ),
      );
      if (response.statusCode != 200) throw ApiException.fromResponse(response);
      final decoded = _decodeJson(response);
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException(
          statusCode: 500,
          message: 'La respuesta paginada del perfil no es válida.',
        );
      }
      final page = CursorPage.fromJson(decoded, PerfilLibroTerminado.fromJson);
      terminados.addAll(page.items);
      cursor = page.hasMore ? page.nextCursor : null;
    } while (cursor?.isNotEmpty == true);

    return PerfilUsuario(
      usuario: metadata.usuario,
      avatarUrl: metadata.avatarUrl,
      resumen: metadata.resumen,
      leyendo: metadata.leyendo,
      terminados: terminados,
      abandonados: metadata.abandonados,
      pendientes: metadata.pendientes,
      generosFavoritos: metadata.generosFavoritos,
      sagas: metadata.sagas,
      historicoMeses: metadata.historicoMeses,
    );
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

    final data = _decodeJson(response);

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

    final data = _decodeJson(response);

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
      return MoodClub.fromJson(_decodeJson(response));
    }

    throw Exception('Error cargando el mood del club');
  }

  Future<bool> registrarMoodClub(String mood) async {
    return _respuestaOk(await _postJson('registrarMoodClub', {'mood': mood}));
  }

  Future<TendenciasClub> getTendenciasClub() async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=tendenciasClub'),
    );

    if (response.statusCode == 200) {
      return TendenciasClub.fromJson(_decodeJson(response));
    }

    throw Exception('Error cargando tendencias');
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

    final data = _decodeJson(response);

    if (data is! Map<String, dynamic>) {
      return {
        'ok': false,
        'mensaje': 'La respuesta del servidor no es válida.',
      };
    }

    return data;
  }

  // ── Logros ──────────────────────────────────────────────────────

  Future<List<UserAchievement>> getAchievements({String? user}) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'action': 'achievements',
        if (user != null && user.isNotEmpty) 'user': user,
      },
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) return [];
    final data = _decodeJson(response);
    if (data is! Map<String, dynamic>) return [];
    final list = data['achievements'] as List<dynamic>? ?? [];
    return list
        .cast<Map<String, dynamic>>()
        .map(UserAchievement.fromJson)
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> getRecentClubAchievements() async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=clubAchievementsRecent'),
    );
    if (response.statusCode != 200) return {};
    final data = _decodeJson(response);
    if (data is! Map<String, dynamic>) return {};
    return data;
  }

  // ── Notificaciones ───────────────────────────────────────────────

  Future<NotificacionesData> getNotificaciones() async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=notificaciones'),
    );
    if (response.statusCode != 200) {
      return const NotificacionesData(notificaciones: [], noLeidas: 0);
    }
    final data = _decodeJson(response);
    if (data is! Map<String, dynamic>) {
      return const NotificacionesData(notificaciones: [], noLeidas: 0);
    }
    return NotificacionesData.fromJson(data);
  }

  Future<CursorPage<Notificacion>> getNotificacionesPage({
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _client.get(
      Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'notificaciones',
          'limit': '$limit',
          if (cursor?.isNotEmpty == true) 'cursor': cursor!,
        },
      ),
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    final decoded = _decodeJson(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 500,
        message: 'La respuesta de notificaciones no es válida.',
      );
    }
    return CursorPage.fromJson(decoded, Notificacion.fromJson);
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

  Future<void> eliminarTodasNotificaciones() async {
    await _client.post(
      Uri.parse('$baseUrl?action=eliminarTodasNotificaciones'),
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

  // ── Afinidad ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAfinidadDetalle(String miembroId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=afinidadDetalle&miembroId=$miembroId'),
    );
    if (response.statusCode != 200) return {};
    final data = _decodeJson(response);
    if (data is! Map<String, dynamic>) return {};
    return data;
  }

  // ── Series overrides ────────────────────────────────────────────

  Future<void> setSeriesOverride({
    required String seriesId,
    required int posicion,
    required String tipo,
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

  // ── General dashboard ───────────────────────────────────────────

  Future<Map<String, dynamic>> getLibrosPorAutor(String autorId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=librosPorAutor&autorId=$autorId'),
    );
    if (response.statusCode != 200) return {};
    final data = _decodeJson(response);
    if (data is! Map<String, dynamic>) return {};
    return data;
  }

  Future<void> guardarOrdenPersonalSaga({
    required String sagaId,
    required List<({String bookId, int posicion})> order,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=saveUserSeriesOrder'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'seriesId': sagaId,
        'order': order
            .map((item) => {'bookId': item.bookId, 'posicion': item.posicion})
            .toList(),
      }),
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    final decoded = _decodeJson(response);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded is Map<String, dynamic>
            ? decoded['mensaje']?.toString() ?? 'No se pudo guardar el orden.'
            : 'No se pudo guardar el orden.',
      );
    }
  }

  Future<Map<String, dynamic>> getClubChallenges() async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=getClubChallenges'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    return _decodeJson(response) as Map<String, dynamic>;
  }

  Future<void> setReadingChallenge({required int target}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=setReadingChallenge'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'target': target}),
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    final decoded = _decodeJson(response);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw ApiException(
        statusCode: response.statusCode,
        message:
            decoded['mensaje']?.toString() ?? 'No se pudo guardar el reto.',
      );
    }
  }

  Future<void> actualizarPaginaActual({
    required String bookId,
    required int pagina,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=actualizarPaginaLibrary'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'bookId': bookId, 'paginaActual': pagina}),
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    final decoded = _decodeJson(response);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded['mensaje']?.toString() ?? 'No se pudo actualizar.',
      );
    }
  }

  // ── Check-in lector ─────────────────────────────────────────────────────────

  /// Registra el check-in del día. Devuelve {ok, date, streak, checkedToday}.
  Future<Map<String, dynamic>> doCheckin({String? nota}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=doCheckin'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'nota': nota}),
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    return _decodeJson(response) as Map<String, dynamic>;
  }

  /// Devuelve el historial de check-ins + racha actual.
  /// [dias] cuántos días hacia atrás recuperar (por defecto 365).
  Future<Map<String, dynamic>> getHistorialCheckin({int dias = 365}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=historialCheckin&dias=$dias'),
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    return _decodeJson(response) as Map<String, dynamic>;
  }

  /// Devuelve los días con actividad lectora del año [anio] para el mapa de calor.
  Future<Map<String, dynamic>> getMapaCalor({int? anio}) async {
    final year = anio ?? DateTime.now().year;
    final response = await _client.get(
      Uri.parse('$baseUrl?action=mapaCalor&anio=$year'),
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    return _decodeJson(response) as Map<String, dynamic>;
  }

  /// Devuelve el resumen Wrapped del año [anio].
  Future<Map<String, dynamic>> getWrappedAnual({int? anio}) async {
    final year = anio ?? DateTime.now().year;
    final response = await _client.get(
      Uri.parse('$baseUrl?action=wrappedAnual&anio=$year'),
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    return _decodeJson(response) as Map<String, dynamic>;
  }
}
