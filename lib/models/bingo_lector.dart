/// Las 25 casillas del bingo lector — retos de book journal sobre el LIBRO
/// en sí (portada, género, formato, autor...), a propósito distintos de los
/// logros de la app (que premian el hábito: rachas, reseñas, check-ins).
/// El orden y las claves deben coincidir exactamente con
/// `BINGO_SQUARE_KEYS` en el backend (src/services/bingo.service.ts).
class BingoCasilla {
  const BingoCasilla(this.key, this.icono, this.etiqueta);
  final String key;
  final String icono;
  final String etiqueta;
}

const kBingoCasillas = <BingoCasilla>[
  BingoCasilla('portada_roja_rosa', '💗', 'Portada roja o rosa'),
  BingoCasilla('portada_amarilla', '💛', 'Portada amarilla'),
  BingoCasilla('portada_blanco_negro', '🖤', 'Portada en blanco y negro'),
  BingoCasilla('ambientado_otro_pais', '🗺️', 'Ambientado en otro país'),
  BingoCasilla('fantasia', '🐉', 'Fantasía'),
  BingoCasilla('thriller_misterio', '🔪', 'Thriller o misterio'),
  BingoCasilla('romance', '💕', 'Romance'),
  BingoCasilla('romantasy', '🌶️', 'Romantasy'),
  BingoCasilla('contemporanea', '📖', 'Novela contemporánea'),
  BingoCasilla('terror', '👻', 'Terror'),
  BingoCasilla('autor_debut', '✍️', 'Autora o autor debut'),
  BingoCasilla('autor_traducido', '🌍', 'Autor traducido'),
  BingoCasilla('termina_saga', '📚', 'Termina una saga'),
  BingoCasilla('relectura', '🔁', 'Una relectura'),
  BingoCasilla('audiolibro', '🎧', 'Un audiolibro'),
  BingoCasilla('mas_500_paginas', '📏', 'Más de 500 páginas'),
  BingoCasilla('menos_150_paginas', '🤏', 'Menos de 150 páginas'),
  BingoCasilla('clasico', '🕰️', 'Un clásico'),
  BingoCasilla('premio_literario', '🏆', 'Ganador de un premio'),
  BingoCasilla('adaptado_pantalla', '🎬', 'Adaptado a pantalla'),
  BingoCasilla('recomendado', '🗣️', 'Recomendado por alguien'),
  BingoCasilla('tbr_mas_de_un_anio', '📌', 'En tu pila +1 año'),
  BingoCasilla('te_hizo_llorar', '😭', 'Un libro que te hizo llorar'),
  BingoCasilla('coescrito', '🧑‍🤝‍🧑', 'Escrito a dos manos'),
  BingoCasilla('elegido_al_azar', '🎲', 'Elegido al azar'),
];

class BingoMarca {
  const BingoMarca({required this.squareKey, required this.nota});
  final String squareKey;
  final String? nota;

  factory BingoMarca.fromJson(Map<String, dynamic> json) => BingoMarca(
    squareKey: json['squareKey']?.toString() ?? '',
    nota: (json['nota']?.toString().trim().isEmpty ?? true)
        ? null
        : json['nota'].toString(),
  );
}

class BingoLector {
  const BingoLector({required this.ok, required this.year, required this.marcadas});
  final bool ok;
  final int year;
  final Map<String, BingoMarca> marcadas;

  factory BingoLector.fromJson(Map<String, dynamic> json) {
    final lista = ((json['marcadas'] as List?) ?? const [])
        .map((e) => BingoMarca.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return BingoLector(
      ok: json['ok'] == true,
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      marcadas: {for (final m in lista) m.squareKey: m},
    );
  }
}
