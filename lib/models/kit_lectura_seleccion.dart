class KitLecturaSeleccion {
  final List<String> paleta;
  final List<String> subrayadores;

  final String atmosferaId;
  final String atmosferaTitulo;
  final String atmosferaDescripcion;
  final String atmosferaIcono;

  final String luz;
  final String bebida;
  final String snack;
  final String musica;
  final String momento;

  const KitLecturaSeleccion({
    this.paleta = const [],
    this.subrayadores = const [],
    this.atmosferaId = '',
    this.atmosferaTitulo = '',
    this.atmosferaDescripcion = '',
    this.atmosferaIcono = '✨',
    this.luz = '',
    this.bebida = '',
    this.snack = '',
    this.musica = '',
    this.momento = '',
  });

  bool get tienePaleta => paleta.isNotEmpty;

  bool get tieneSubrayadores => subrayadores.isNotEmpty;

  bool get tieneAtmosfera {
    return atmosferaId.trim().isNotEmpty || atmosferaTitulo.trim().isNotEmpty;
  }

  KitLecturaSeleccion copyWith({
    List<String>? paleta,
    List<String>? subrayadores,
    String? atmosferaId,
    String? atmosferaTitulo,
    String? atmosferaDescripcion,
    String? atmosferaIcono,
    String? luz,
    String? bebida,
    String? snack,
    String? musica,
    String? momento,
  }) {
    return KitLecturaSeleccion(
      paleta: paleta ?? this.paleta,
      subrayadores: subrayadores ?? this.subrayadores,
      atmosferaId: atmosferaId ?? this.atmosferaId,
      atmosferaTitulo: atmosferaTitulo ?? this.atmosferaTitulo,
      atmosferaDescripcion: atmosferaDescripcion ?? this.atmosferaDescripcion,
      atmosferaIcono: atmosferaIcono ?? this.atmosferaIcono,
      luz: luz ?? this.luz,
      bebida: bebida ?? this.bebida,
      snack: snack ?? this.snack,
      musica: musica ?? this.musica,
      momento: momento ?? this.momento,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paleta': paleta,
      'subrayadores': subrayadores,
      'atmosferaId': atmosferaId,
      'atmosferaTitulo': atmosferaTitulo,
      'atmosferaDescripcion': atmosferaDescripcion,
      'atmosferaIcono': atmosferaIcono,
      'luz': luz,
      'bebida': bebida,
      'snack': snack,
      'musica': musica,
      'momento': momento,
    };
  }

  factory KitLecturaSeleccion.fromJson(Map<String, dynamic> json) {
    return KitLecturaSeleccion(
      paleta: _listaStrings(json['paleta']),
      subrayadores: _listaStrings(json['subrayadores']),
      atmosferaId: json['atmosferaId']?.toString() ?? '',
      atmosferaTitulo: json['atmosferaTitulo']?.toString() ?? '',
      atmosferaDescripcion: json['atmosferaDescripcion']?.toString() ?? '',
      atmosferaIcono: json['atmosferaIcono']?.toString() ?? '✨',
      luz: json['luz']?.toString() ?? '',
      bebida: json['bebida']?.toString() ?? '',
      snack: json['snack']?.toString() ?? '',
      musica: json['musica']?.toString() ?? '',
      momento: json['momento']?.toString() ?? '',
    );
  }

  static List<String> _listaStrings(dynamic valor) {
    if (valor is! List) {
      return const [];
    }

    return valor
        .map((elemento) => elemento.toString())
        .where((elemento) => elemento.trim().isNotEmpty)
        .toList(growable: false);
  }
}
