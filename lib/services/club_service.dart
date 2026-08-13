import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/club_membership.dart';
import '../utils/app_config.dart';
import 'authenticated_http_client.dart';
import 'http_response_handler.dart';

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
    await _request(
      'crearClub',
      body: {'nombre': nombre.trim(), 'descripcion': descripcion.trim()},
    );
  }

  Future<void> joinClub(String codigo) async {
    await _request('unirseClub', body: {'codigo': codigo.trim()});
  }

  Future<void> selectClub(String clubId) async {
    await _request('seleccionarClub', body: {'clubId': clubId});
  }

  Future<String> getInvite(String clubId) async {
    final data = await _request('invitacionClub', body: {'clubId': clubId});
    return data['codigo']?.toString() ?? '';
  }

  Future<Map<String, dynamic>> _request(
    String action, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final params = {'action': action, ...?query};
    final uri = Uri.parse(AppConfig.baseUrl).replace(queryParameters: params);
    final response = body == null
        ? await _client.get(uri)
        : await _client.post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          );
    return HttpResponseHandler.decodeObject(response);
  }

  /// Crea (o reactiva) el espacio lector personal del usuario.
  /// Es idempotente: si ya existe, simplemente lo selecciona como activo.
  Future<Map<String, dynamic>> crearEspacioPersonal() async {
    return _request('crearEspacioPersonal', body: {});
  }

  Future<void> leaveClub(String clubId) async {
    await _request('salirClub', body: {'clubId': clubId});
  }

  Future<void> updateClub({
    required String clubId,
    String? nombre,
    String? descripcion,
    String? avatarUrl,
  }) async {
    await _request(
      'editarClub',
      body: {
        'clubId': clubId,
        'nombre': ?nombre,
        'descripcion': ?descripcion,
        'avatarUrl': ?avatarUrl,
      },
    );
  }

  Future<List<ClubMember>> getClubMembers(String clubId) async {
    final data = await _request('miembrosClub', query: {'clubId': clubId});
    final list = data['miembros'] as List<dynamic>? ?? [];
    return list
        .cast<Map<String, dynamic>>()
        .map(ClubMember.fromJson)
        .toList(growable: false);
  }
}
