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
    return GeneralDashboard.fromJson(data);
  }
}
