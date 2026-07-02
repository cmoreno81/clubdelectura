import 'dart:convert';

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

class ApiService {
  static const String baseUrl =
      'https://script.google.com/macros/s/AKfycby-vv3hiWByr54VyA6xX2ADvz6tANKZ_qNluALe3Ft3zvKAjPbETk8tO7TulTmnV9Ua/exec';

  Future<List<Usuario>> getUsuarios() async {
    final response = await http.get(Uri.parse('$baseUrl?action=usuarios'));
    final List data = jsonDecode(response.body);

    return data.map((e) => Usuario.fromJson(e)).toList();
  }

  Future<Dashboard> getDashboard() async {
    final response = await http.get(Uri.parse('$baseUrl?action=dashboard'));

    if (response.statusCode == 200) {
      return Dashboard.fromJson(jsonDecode(response.body));
    }

    throw Exception('Error cargando dashboard');
  }

  Future<List<Libro>> getLibros() async {
    final usuario = await UsuarioService().obtenerUsuario();

    final response = await http.get(
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
    final response = await http.get(
      Uri.parse('$baseUrl?action=librosFinalizados'),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data.map((e) => LibroFinalizado.fromJson(e)).toList();
    }

    throw Exception('Error cargando finalizados');
  }

  Future<void> crearLibro(NuevoLibro libro) async {
    final response = await http.post(
      Uri.parse('$baseUrl?action=crearLibro'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode(libro.toJson()),
    );
  }

  Future<void> actualizarEstado({
    required String usuario,
    required String libro,
    required String estado,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl?action=actualizarEstado'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({'usuario': usuario, 'libro': libro, 'estado': estado}),
    );

    if (response.statusCode != 200 && response.statusCode != 302) {
      throw Exception('Error actualizando estado');
    }
  }

  Future<void> actualizarValoracion({
    required String usuario,
    required String libro,
    required String valoracion,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl?action=actualizarValoracion'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({
        'usuario': usuario,
        'libro': libro,
        'valoracion': valoracion,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 302) {
      throw Exception('Error actualizando valoración');
    }
  }

  Future<LibrosData> getLibrosData() async {
    final libros = await getLibros();

    final finalizados = await getLibrosFinalizados();

    return LibrosData(libros: libros, finalizados: finalizados);
  }

  Future<Ranking> getRanking() async {
    final response = await http.get(Uri.parse('$baseUrl?action=ranking'));

    if (response.statusCode == 200) {
      return Ranking.fromJson(jsonDecode(response.body));
    }

    throw Exception('Error cargando ranking');
  }

  Future<ClubvisionData> getClubvision() async {
    final usuario = await UsuarioService().obtenerUsuario();

    final response = await http.get(
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
    final response = await http.get(
      Uri.parse('$baseUrl?action=historialClubvision'),
    );

    final List data = jsonDecode(response.body);

    return data.map((e) => HistorialClubvision.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> anadirLibroExistente({
    required String usuario,
    required String libro,
  }) async {
    final response = await http.get(
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

  Future<bool> enviarVotacion({
    required String usuario,
    required List<String> votos,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'action': 'enviarVotacion',
        'usuario': usuario,
        'v1': votos.length > 0 ? votos[0] : '',
        'v2': votos.length > 1 ? votos[1] : '',
        'v3': votos.length > 2 ? votos[2] : '',
        'v4': votos.length > 3 ? votos[3] : '',
        'v5': votos.length > 4 ? votos[4] : '',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return false;
    }

    final json = jsonDecode(response.body);

    return json["ok"] == true;
  }
}
