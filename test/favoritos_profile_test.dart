import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:club_lectura_app/models/perfil_usuario.dart';
import 'package:club_lectura_app/services/api_service.dart';
import 'package:club_lectura_app/services/favoritos_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

LibroFavorito favorito(int id) => LibroFavorito(
  id: 'book-$id',
  title: 'Libro $id',
  coverUrl: 'https://example.invalid/$id.jpg',
);

void main() {
  test(
    'quitar desde la portada actualiza inmediatamente y usa toggle',
    () async {
      final response = Completer<http.Response>();
      late http.Request request;
      final service = FavoritosService.forTesting(
        ApiService(
          client: MockClient((req) {
            request = req;
            return response.future;
          }),
        ),
      );
      service.establecerFavoritos([favorito(1), favorito(2)]);

      final operation = service.toggle('book-1', 'Libro 1');
      expect(service.favoritos.map((f) => f.id), ['book-2']);
      expect(service.operando, isTrue);
      response.complete(
        http.Response(jsonEncode({'ok': true, 'isFavorite': false}), 200),
      );

      expect((await operation).ok, isTrue);
      expect(request.url.queryParameters['action'], 'toggleFavorito');
    },
  );

  test('sustituye con cinco favoritos y conserva la posición', () async {
    final response = Completer<http.Response>();
    final service = FavoritosService.forTesting(
      ApiService(client: MockClient((_) => response.future)),
    );
    service.establecerFavoritos(List.generate(5, favorito));

    final operation = service.reemplazar(favorito(2), favorito(8));
    expect(service.favoritos, hasLength(5));
    expect(service.favoritos[2].id, 'book-8');
    response.complete(
      http.Response(
        jsonEncode({
          'ok': true,
          'favorito': {'id': 'book-8', 'title': 'Libro 8'},
        }),
        200,
      ),
    );

    expect((await operation).ok, isTrue);
    expect(service.favoritos[2].id, 'book-8');
  });

  test(
    'restaura visualmente el favorito original si falla la sustitución',
    () async {
      final response = Completer<http.Response>();
      final originales = List.generate(5, favorito);
      final service = FavoritosService.forTesting(
        ApiService(client: MockClient((_) => response.future)),
      );
      service.establecerFavoritos(originales);

      final operation = service.reemplazar(originales[1], favorito(9));
      expect(service.favoritos[1].id, 'book-9');
      response.complete(
        http.Response(
          jsonEncode({'ok': false, 'mensaje': 'Fallo controlado'}),
          200,
        ),
      );

      final result = await operation;
      expect(result.ok, isFalse);
      expect(result.mensaje, 'Fallo controlado');
      expect(service.favoritos.map((f) => f.id), originales.map((f) => f.id));
    },
  );

  test('los perfiles ajenos no conectan una acción a las portadas', () {
    final source = File(
      'lib/pages/perfil_usuario_page.dart',
    ).readAsStringSync();
    expect(source, contains('onTap: esMiPerfil && libro != null'));
    expect(source, contains("? () => _mostrarAcciones(context, libro)"));
    expect(source, contains("'Cambiar favorito'"));
    expect(source, contains("'Quitar de favoritos'"));
    expect(source, contains("'Cancelar'"));
  });
}
