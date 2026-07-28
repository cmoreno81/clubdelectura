import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/club_membership.dart';
import '../utils/app_config.dart';
import 'api_exception.dart';
import 'authenticated_http_client.dart';

class ClubService {
  ClubService({http.Client? client})
    : _client = client ?? AuthenticatedHttpClient();

  final http.Client _client;

  Future<MyClubs> getMyClubs() async {
    final data = await _request('misClubes');
    return MyClubs.fromJson(data);
  }

  Future<void> createClub({
    required String nombre,
    String descripcion = '',
  }) async {
    await _request('crearClub', {
      'nombre': nombre.trim(),
      'descripcion': descripcion.trim(),
    });
  }

  Future<void> joinClub(String codigo) async {
    await _request('unirseClub', {'codigo': codigo.trim()});
  }

  Future<void> selectClub(String clubId) async {
    await _request('seleccionarClub', {'clubId': clubId});
  }

  Future<String> getInvite(String clubId) async {
    final data = await _request('invitacionClub', {'clubId': clubId});
    return data['codigo']?.toString() ?? '';
  }

  Future<Map<String, dynamic>> _request(
    String action, [
    Map<String, dynamic>? body,
  ]) async {
    final uri = Uri.parse(
      AppConfig.baseUrl,
    ).replace(queryParameters: {'action': action});
    final response = body == null
        ? await _client.get(uri)
        : await _client.post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromResponse(response);
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 500,
        message: 'La respuesta del servidor no es válida.',
      );
    }
    return data;
  }
}
