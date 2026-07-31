import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/general_dashboard.dart';
import '../utils/app_config.dart';
import 'api_exception.dart';
import 'authenticated_http_client.dart';

class GeneralDashboardService {
  GeneralDashboardService({http.Client? client})
    : _client = client ?? AuthenticatedHttpClient();

  final http.Client _client;

  Future<GeneralDashboard> load() async {
    final response = await _client.get(
      Uri.parse(
        AppConfig.baseUrl,
      ).replace(queryParameters: {'action': 'dashboardGeneral'}),
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
    await _completeSeriesPreview(data);
    return GeneralDashboard.fromJson(data);
  }

  Future<void> _completeSeriesPreview(Map<String, dynamic> dashboard) async {
    final user = Map<String, dynamic>.from(dashboard['usuario'] as Map? ?? {});
    final userName = user['nombre']?.toString().trim() ?? '';
    if (userName.isEmpty) return;

    try {
      final response = await _client.get(
        Uri.parse(AppConfig.baseUrl).replace(
          queryParameters: {
            'action': 'perfilUsuario',
            'perfil': userName,
          },
        ),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return;
      final sagas = (decoded['sagas'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) {
            final state = item['estado']?.toString() ?? '';
            return state == 'EN_CURSO' || state == 'PENDIENTE';
          })
          .toList(growable: false)
        ..sort((left, right) {
          final leftState = left['estado']?.toString() ?? '';
          final rightState = right['estado']?.toString() ?? '';
          if (leftState != rightState) {
            return leftState == 'EN_CURSO' ? -1 : 1;
          }
          final leftRead = (left['leidos'] as num?)?.toInt() ?? 0;
          final rightRead = (right['leidos'] as num?)?.toInt() ?? 0;
          return rightRead.compareTo(leftRead);
        });
      if (sagas.isEmpty) return;

      dashboard['sagasAbiertas'] = sagas.take(6).map((item) {
        final volumes = (item['volumenes'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((volume) => Map<String, dynamic>.from(volume))
            .toList(growable: false);
        final next = item['siguiente'] is Map
            ? Map<String, dynamic>.from(item['siguiente'] as Map)
            : null;
        final known = (item['totalConocidos'] as num?)?.toInt() ?? 0;
        final expected = (item['totalSaga'] as num?)?.toInt() ?? 0;
        final cover = next?['coverUrl']?.toString().trim();
        final fallbackCover = volumes
            .map((volume) => volume['coverUrl']?.toString().trim() ?? '')
            .firstWhere((value) => value.isNotEmpty, orElse: () => '');
        return {
          'id': item['id'],
          'nombre': item['nombre'],
          'leidos': item['leidos'],
          'total': expected > known ? expected : known,
          'estado': item['estado'],
          'coverUrl': cover?.isNotEmpty == true ? cover : fallbackCover,
          'siguiente': next == null
              ? null
              : {
                  'id': next['bookId'],
                  'titulo': next['titulo'],
                  'coverUrl': next['coverUrl'],
                  'enMiBiblioteca': next['estado'] != 'NO_ANADIDO',
                },
        };
      }).toList(growable: false);
    } catch (_) {
      // El dashboard sigue siendo usable aunque el complemento de sagas falle.
    }
  }
}
