import 'dart:convert';

import 'package:club_lectura_app/models/lectura_activa.dart';
import 'package:club_lectura_app/models/lectura_compartida.dart';
import 'package:club_lectura_app/models/mi_voto.dart';
import 'package:http/http.dart' as http;

import '../models/dashboard.dart';
import '../models/libro.dart';
import '../models/libro_finalizado.dart';
import '../models/nuevo_libro.dart';
import '../models/libros_data.dart';
import '../models/ranking.dart';
import '../models/clubvision.dart';
import '../models/historial_clubvision.dart';
import '../models/usuario.dart';
import 'usuario_service.dart';
import '../models/como_votaron.dart';
import '../models/comentarios_capitulo.dart';
import '../models/configuracion_lectura.dart';
import '../models/conversacion_libro.dart';

class ApiService {
  static const String baseUrl =
      'https://script.google.com/macros/s/AKfycbwh7B2YLDOpxmmnwih4IphkaFun3xFuqp0vkB9vB2vzSJcgpAHlQz7vzY7IDgrt3m4N/exec';
  static final http.Client _client = http.Client();

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

    print(response.body);

    throw Exception('Error cargando dashboard');
  }

  Future<List<Libro>> getLibros() async {
    final usuario = await UsuarioService().obtenerUsuario();

    final response = await _client.get(
      Uri.parse(
        '$baseUrl?action=libros'
        '&usuario=${Uri.encodeComponent(usuario ?? "")}',
      ),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data.map((e) => Libro.fromJson(e)).toList();
    }

    throw Exception('Error cargando libros');
  }

  Future<List<LibroFinalizado>> getLibrosFinalizados() async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=librosFinalizados'),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data.map((e) => LibroFinalizado.fromJson(e)).toList();
    }

    throw Exception('Error cargando finalizados');
  }

  Future<bool> iniciarLectura({
    required String usuario,
    required String libro,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        "action": "iniciarLectura",
        "usuario": usuario,
        "libro": libro,
      },
    );

    final response = await _client.get(uri);

    return _respuestaOk(response);
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
    final usuario = await UsuarioService().obtenerUsuario();

    final response = await _client.get(
      Uri.parse(
        '$baseUrl?action=comentariosLectura'
        '&libro=${Uri.encodeComponent(libro)}'
        '&capitulo=${Uri.encodeComponent(capitulo)}'
        '&usuario=${Uri.encodeComponent(usuario ?? "")}',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception("Error cargando comentarios");
    }

    return ComentariosCapitulo.fromJson(jsonDecode(response.body));
  }

  Future<void> guardarComentarioLectura({
    required String libro,
    required String capitulo,
    required String usuario,
    required String comentario,
  }) async {
    await _client.get(
      Uri.parse(
        '$baseUrl?action=guardarComentarioLectura'
        '&libro=${Uri.encodeComponent(libro)}'
        '&capitulo=${Uri.encodeComponent(capitulo)}'
        '&usuario=${Uri.encodeComponent(usuario)}'
        '&comentario=${Uri.encodeComponent(comentario)}',
      ),
    );
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
        "usuario": usuario,
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
    final response = await _client.get(
      Uri.parse('$baseUrl?action=lecturasActivas'),
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
    String tipo = "LIBRE",
  }) async {
    final response = await _client.get(
      Uri.parse(
        '$baseUrl?action=crearLectura'
        '&libro=${Uri.encodeComponent(libro)}'
        '&capitulos=$capitulos'
        '&prologo=${prologo ? 1 : 0}'
        '&epilogo=${epilogo ? 1 : 0}'
        '&tipo=$tipo',
      ),
    );

    return _respuestaOk(response);
  }

  Future<ConfiguracionLectura> getConfiguracionLectura({
    required String libro,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {"action": "configuracionLectura", "libro": libro},
    );

    final response = await http.get(uri);

    final json = jsonDecode(response.body);

    return ConfiguracionLectura.fromJson(json);
  }

  Future<List<ConversacionLibro>> getConversacionesLibro({
    required String libro,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {"action": "conversacionesLibro", "libro": libro},
    );

    final response = await http.get(uri);

    final json = jsonDecode(response.body) as List;

    return json.map((e) => ConversacionLibro.fromJson(e)).toList();
  }

  Future<void> crearLibro(NuevoLibro libro) async {
    await _client.post(
      Uri.parse('$baseUrl?action=crearLibro'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode(libro.toJson()),
    );
  }

  Future<List<ComoVotaron>> getComoVotaron() async {
    final response = await _client.get(
      Uri.parse('$baseUrl?action=comoVotaron'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);

      return json.map((e) => ComoVotaron.fromJson(e)).toList();
    }

    throw Exception('Error cargando las votaciones');
  }

  Future<bool> actualizarEstado({
    required String usuario,
    required String libro,
    required String estado,
    String? valoracion,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl?action=actualizarEstado'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'usuario': usuario,
        'libro': libro,
        'estado': estado,
        'valoracion': valoracion ?? "",
      }),
    );

    if (response.statusCode == 302) {
      // Apps Script ya ejecutó la operación aunque responda con redirect.
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
        "usuario": usuario,
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
      body: jsonEncode({
        'usuario': usuario,
        'libro': libro,
        'valoracion': valoracion,
      }),
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

  Future<Ranking> getRanking() async {
    final response = await _client.get(Uri.parse('$baseUrl?action=ranking'));

    if (response.statusCode == 200) {
      return Ranking.fromJson(jsonDecode(response.body));
    }

    throw Exception('Error cargando ranking');
  }

  Future<ClubvisionData> getClubvision() async {
    final usuario = (await UsuarioService().obtenerUsuario())?.trim();
    final response = await _client.get(
      Uri.parse(
        '$baseUrl?action=clubvision&usuario=${Uri.encodeComponent(usuario ?? "")}',
      ),
    );

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

    return data.map((e) => HistorialClubvision.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> anadirLibroExistente({
    required String usuario,
    required String libro,
  }) async {
    final response = await _client.get(
      Uri.parse(
        '$baseUrl?action=anadirLibroExistente'
        '&usuario=${Uri.encodeComponent(usuario)}'
        '&libro=${Uri.encodeComponent(libro)}',
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

  Future<MiVoto> getMiVoto(String usuario) async {
    final response = await _client.get(
      Uri.parse(
        '$baseUrl?action=miVoto&usuario=${Uri.encodeComponent(usuario)}',
      ),
    );

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
        'usuario': usuario,
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
  }) async {
    final usuario = await UsuarioService().obtenerUsuario();

    final response = await _client.get(
      Uri.parse(
        '$baseUrl?action=toggleLikeComentario'
        '&id=${Uri.encodeComponent(comentarioId)}'
        '&usuario=${Uri.encodeComponent(usuario ?? "")}',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception("Error dando like");
    }

    return jsonDecode(response.body);
  }
}
