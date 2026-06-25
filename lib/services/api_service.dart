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

class ApiService {

  static const String baseUrl =
      'https://script.google.com/macros/s/AKfycbyig_QGym2sTWmG16Wlw4pgfP57sVz86LuM58s3n84vLAVM6QK-fRrw89wIiyCaS4h0/exec';

  Future<List<Usuario>> getUsuarios() async {

    final response =
        await http.get(

      Uri.parse(
        '$baseUrl?action=usuarios',
      ),
    );
    print(response.statusCode);
print(response.body);
    final List data =
        jsonDecode(
          response.body,
        );

    return data

        .map(
          (e) =>
              Usuario.fromJson(e),
        )

        .toList();
  }
  Future<Dashboard> getDashboard() async {

    final response =
        await http.get(
      Uri.parse(
        '$baseUrl?action=dashboard',
      ),
    );

    print(
        'Dashboard status: ${response.statusCode}',
        );

        print(
        'Dashboard body: ${response.body}',
        );
    if (response.statusCode == 200) {

      return Dashboard.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      'Error cargando dashboard',
    );
  }

  Future<List<Libro>> getLibros() async {

    final response =
        await http.get(
      Uri.parse(
        '$baseUrl?action=libros',
      ),
    );

    if (response.statusCode == 200) {

      final List data =
          jsonDecode(
        response.body,
      );

      return data
          .map(
            (e) =>
                Libro.fromJson(e),
          )
          .toList();
    }

    throw Exception(
      'Error cargando libros',
    );
  }

  Future<List<LibroFinalizado>>
      getLibrosFinalizados() async {

    final response =
        await http.get(
      Uri.parse(
        '$baseUrl?action=librosFinalizados',
      ),
    );

    if (response.statusCode == 200) {

      final List data =
          jsonDecode(
        response.body,
      );

      return data
          .map(
            (e) =>
                LibroFinalizado
                    .fromJson(e),
          )
          .toList();
    }

    throw Exception(
      'Error cargando finalizados',
    );
  }

  Future<void> crearLibro(
    NuevoLibro libro,
  ) async {

    final response =
        await http.post(

      Uri.parse(
        '$baseUrl?action=crearLibro',
      ),

      headers: {
        'Content-Type':
            'application/json',
      },

      body: jsonEncode(
        libro.toJson(),
      ),
    );

    print(
      'STATUS: ${response.statusCode}',
    );

    print(
      'BODY: ${response.body}',
    );
  }

  Future<void> actualizarEstado({

    required String usuario,
    required String libro,
    required String estado,

  }) async {

    final response =
        await http.post(

      Uri.parse(
        '$baseUrl?action=actualizarEstado',
      ),

      headers: {
        'Content-Type':
            'application/json',
      },

      body: jsonEncode({

        'usuario': usuario,
        'libro': libro,
        'estado': estado,

      }),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 302) {

      throw Exception(
        'Error actualizando estado',
      );
    }
  }

  Future<void> actualizarValoracion({

    required String usuario,
    required String libro,
    required String valoracion,

  }) async {

    final response =
        await http.post(

      Uri.parse(
        '$baseUrl?action=actualizarValoracion',
      ),

      headers: {
        'Content-Type':
            'application/json',
      },

      body: jsonEncode({

        'usuario': usuario,
        'libro': libro,
        'valoracion': valoracion,

      }),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 302) {

      throw Exception(
        'Error actualizando valoración',
      );
    }
  }

  Future<LibrosData> getLibrosData() async {

  final libros =
      await getLibros();

  final finalizados =
      await getLibrosFinalizados();

  return LibrosData(
    libros: libros,
    finalizados: finalizados,
  );
}

Future<Ranking> getRanking() async {

  final response =
      await http.get(

    Uri.parse(
      '$baseUrl?action=ranking',
    ),
  );

  if (response.statusCode == 200) {

    return Ranking.fromJson(
      jsonDecode(
        response.body,
      ),
    );
  }

  throw Exception(
    'Error cargando ranking',
  );
}
Future<ClubvisionData>
    getClubvision() async {

  final response =
      await http.get(

    Uri.parse(
      '$baseUrl?action=clubvision',
    ),
  );

  if (response.statusCode ==
      200) {

    return ClubvisionData.fromJson(

      jsonDecode(
        response.body,
      ),
    );
  }

  throw Exception(
    'Error cargando Clubvisión',
  );
}

Future<List<HistorialClubvision>>
    getHistorialClubvision() async {

  final response = await http.get(

    Uri.parse(
      '$baseUrl?action=historialClubvision',
    ),
  );

  final List data =
      jsonDecode(response.body);

  return data

      .map(
        (e) =>
            HistorialClubvision.fromJson(e),
      )

      .toList();
}
}