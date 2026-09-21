import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/club_directory.dart';
import '../models/club_membership.dart';
import '../models/club_wrapped.dart';
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
    final params = {'action': 'seleccionarClub'};
    final uri = Uri.parse(AppConfig.baseUrl).replace(queryParameters: params);
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'clubId': clubId}),
    );
    // Solo verificamos que el servidor respondió con éxito (no necesitamos el cuerpo).
    HttpResponseHandler.ensureSuccess(response);
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

  Future<void> deleteClub(String clubId) async {
    await _request('eliminarClub', body: {'clubId': clubId});
  }

  Future<void> transferirPropiedad({
    required String clubId,
    required String nuevoOwnerId,
  }) async {
    await _request(
      'transferirPropiedadClub',
      body: {'clubId': clubId, 'nuevoOwnerId': nuevoOwnerId},
    );
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

  // ── Directorio de clubes públicos ───────────────────────────────────────

  /// Cambia la visibilidad del club entre 'PUBLIC' y 'PRIVATE'. Solo
  /// owner/admin.
  Future<void> cambiarVisibilidadClub({
    required String clubId,
    required bool publico,
  }) async {
    await _request(
      'cambiarVisibilidadClub',
      body: {
        'clubId': clubId,
        'visibility': publico ? 'PUBLIC' : 'PRIVATE',
      },
    );
  }

  /// Lista de clubes públicos, opcionalmente filtrada por nombre.
  Future<List<ClubPublico>> getClubesPublicos({String? search}) async {
    final data = await _request(
      'clubesPublicos',
      query: (search != null && search.trim().isNotEmpty)
          ? {'q': search.trim()}
          : null,
    );
    final list = data['clubes'] as List<dynamic>? ?? [];
    return list
        .cast<Map<String, dynamic>>()
        .map(ClubPublico.fromJson)
        .toList(growable: false);
  }

  /// Solicita unirse a un club público. Queda pendiente hasta que
  /// owner/admin la resuelva.
  Future<void> solicitarUnirseClub(String clubId) async {
    await _request('solicitarUnirseClub', body: {'clubId': clubId});
  }

  /// Solicitudes pendientes de un club. Solo owner/admin.
  Future<List<SolicitudClub>> getSolicitudesClub(String clubId) async {
    final data = await _request('solicitudesClub', query: {'clubId': clubId});
    final list = data['solicitudes'] as List<dynamic>? ?? [];
    return list
        .cast<Map<String, dynamic>>()
        .map(SolicitudClub.fromJson)
        .toList(growable: false);
  }

  /// Acepta o rechaza una solicitud pendiente. Solo owner/admin.
  Future<void> responderSolicitudClub({
    required String clubId,
    required String requestId,
    required bool aceptar,
  }) async {
    await _request(
      'responderSolicitudClub',
      body: {'clubId': clubId, 'requestId': requestId, 'aceptar': aceptar},
    );
  }

  /// Club Wrapped: el resumen anual del club (libro del año, favorito,
  /// libros y comentarios, racha). Por defecto, el año en curso.
  Future<ClubWrapped> getClubWrapped(String clubId, {int? year}) async {
    final data = await _request(
      'clubWrapped',
      query: {
        'clubId': clubId,
        'year': '${year ?? DateTime.now().year}',
      },
    );
    return ClubWrapped.fromJson(data);
  }
}
