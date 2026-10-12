import 'package:http/http.dart' as http;

import '../utils/app_config.dart';
import '../utils/genero_utils.dart';
import 'authenticated_http_client.dart';
import 'http_response_handler.dart';

/// Libro de Talento emergente que toca destacar esta semana en Inicio.
class TalentoDeLaSemana {
  const TalentoDeLaSemana({
    required this.bookId,
    required this.titulo,
    required this.autoria,
    required this.coverUrl,
    required this.generos,
    required this.nota,
    this.picante,
    this.tropos = const [],
  });

  final String bookId;
  final String titulo;
  final String autoria;
  final String coverUrl;
  final List<String> generos;
  final String nota;
  final int? picante;
  final List<String> tropos;

  static TalentoDeLaSemana? fromJson(Map<String, dynamic> json) {
    final libro = json['libro'];
    if (libro is! Map) return null;
    final m = Map<String, dynamic>.from(libro);
    final id = m['bookId']?.toString() ?? '';
    final titulo = m['titulo']?.toString() ?? '';
    if (id.isEmpty || titulo.isEmpty) return null;
    return TalentoDeLaSemana(
      bookId: id,
      titulo: titulo,
      autoria: m['autora']?.toString() ?? '',
      coverUrl: m['coverUrl']?.toString() ?? '',
      generos: leerGeneros(m['generos']),
      nota: m['notaAutora']?.toString() ?? '',
      picante: (m['picanteAutora'] as num?)?.toInt(),
      tropos: leerGeneros(m['troposAutora']),
    );
  }
}

class TalentoSemanaService {
  TalentoSemanaService({http.Client? client})
    : _client = client ?? AuthenticatedHttpClient();

  final http.Client _client;

  /// `null` si esta semana no hay ningún libro con sello.
  Future<TalentoDeLaSemana?> cargar() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/books/autora-de-la-semana');
    final data = HttpResponseHandler.decodeObject(await _client.get(uri));
    return TalentoDeLaSemana.fromJson(data);
  }
}
