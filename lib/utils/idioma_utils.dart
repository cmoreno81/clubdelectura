/// Códigos de idioma que acepta el backend (ver bookLanguageSchema).
const idiomasSoportados = [
  'es', 'en', 'fr', 'de', 'it', 'pt', 'nl', 'ko', 'ru',
  'ca', 'eu', 'gl', 'ja', 'zh', 'ar', 'sv', 'no', 'da', 'fi', 'pl', 'el', 'tr',
];

String nombreIdioma(String codigo) {
  switch (codigo.toLowerCase()) {
    case 'es':
      return 'Español';
    case 'en':
      return 'Inglés';
    case 'fr':
      return 'Francés';
    case 'de':
      return 'Alemán';
    case 'it':
      return 'Italiano';
    case 'pt':
      return 'Portugués';
    case 'nl':
      return 'Neerlandés';
    case 'ko':
      return 'Coreano';
    case 'ru':
      return 'Ruso';
    case 'ca':
      return 'Catalán';
    case 'eu':
      return 'Euskera';
    case 'gl':
      return 'Gallego';
    case 'ja':
      return 'Japonés';
    case 'zh':
      return 'Chino';
    case 'ar':
      return 'Árabe';
    case 'sv':
      return 'Sueco';
    case 'no':
      return 'Noruego';
    case 'da':
      return 'Danés';
    case 'fi':
      return 'Finlandés';
    case 'pl':
      return 'Polaco';
    case 'el':
      return 'Griego';
    case 'tr':
      return 'Turco';
    default:
      return codigo.toUpperCase();
  }
}

String banderaIdioma(String codigo) {
  switch (codigo.toLowerCase()) {
    case 'es':
      return '🇪🇸';
    case 'en':
      return '🇬🇧';
    case 'fr':
      return '🇫🇷';
    case 'de':
      return '🇩🇪';
    case 'it':
      return '🇮🇹';
    case 'pt':
      return '🇵🇹';
    case 'nl':
      return '🇳🇱';
    case 'ko':
      return '🇰🇷';
    case 'ru':
      return '🇷🇺';
    case 'ja':
      return '🇯🇵';
    case 'zh':
      return '🇨🇳';
    case 'ar':
      return '🇸🇦';
    case 'sv':
      return '🇸🇪';
    case 'no':
      return '🇳🇴';
    case 'da':
      return '🇩🇰';
    case 'fi':
      return '🇫🇮';
    case 'pl':
      return '🇵🇱';
    case 'el':
      return '🇬🇷';
    case 'tr':
      return '🇹🇷';
    default:
      // ca/eu/gl y cualquier otro sin bandera de país propia.
      return '🌐';
  }
}

/// Agrupa libros (mapas con la clave `idioma`) por idioma para enseñarlos por secciones.
/// Orden: español primero, inglés después, el resto por nombre y «sin idioma» al final.
/// Dentro de cada grupo, por título. Un libro sin idioma conocido va en el grupo de código ''.
List<({String codigo, List<Map<String, dynamic>> libros})> agruparLibrosPorIdioma(
  List<Map<String, dynamic>> libros,
) {
  final porIdioma = <String, List<Map<String, dynamic>>>{};
  for (final libro in libros) {
    final codigo = (libro['idioma']?.toString() ?? '').trim().toLowerCase();
    porIdioma.putIfAbsent(codigo, () => []).add(libro);
  }
  int prioridad(String codigo) => switch (codigo) {
    'es' => 0,
    'en' => 1,
    '' => 3,
    _ => 2,
  };
  final codigos = porIdioma.keys.toList()
    ..sort((a, b) {
      final porPrioridad = prioridad(a).compareTo(prioridad(b));
      return porPrioridad != 0
          ? porPrioridad
          : nombreIdioma(a).compareTo(nombreIdioma(b));
    });
  return [
    for (final codigo in codigos)
      (
        codigo: codigo,
        libros: porIdioma[codigo]!
          ..sort(
            (a, b) => (a['titulo']?.toString() ?? '').toLowerCase().compareTo(
              (b['titulo']?.toString() ?? '').toLowerCase(),
            ),
          ),
      ),
  ];
}
