/// Una persona en la lista de amistades o en una solicitud.
class PersonaAmistad {
  const PersonaAmistad({required this.nombre, this.avatarUrl = ''});

  final String nombre;
  final String avatarUrl;

  factory PersonaAmistad.fromJson(Map<String, dynamic> json) => PersonaAmistad(
    nombre: json['nombre']?.toString() ?? '',
    avatarUrl: json['avatarUrl']?.toString() ?? '',
  );
}

/// Cómo está la relación con una persona que sale en una búsqueda.
enum EstadoAmistad {
  ninguna,
  enviada,
  recibida,
  amiga;

  static EstadoAmistad desde(String? valor) => switch (valor) {
    'ENVIADA' => EstadoAmistad.enviada,
    'RECIBIDA' => EstadoAmistad.recibida,
    'AMIGA' => EstadoAmistad.amiga,
    _ => EstadoAmistad.ninguna,
  };
}

class PersonaBuscada extends PersonaAmistad {
  const PersonaBuscada({
    required super.nombre,
    super.avatarUrl,
    this.estado = EstadoAmistad.ninguna,
  });

  final EstadoAmistad estado;

  factory PersonaBuscada.fromJson(Map<String, dynamic> json) => PersonaBuscada(
    nombre: json['nombre']?.toString() ?? '',
    avatarUrl: json['avatarUrl']?.toString() ?? '',
    estado: EstadoAmistad.desde(json['estado']?.toString()),
  );
}

class AmistadesData {
  const AmistadesData({
    this.miCodigo = '',
    this.amistades = const [],
    this.recibidas = const [],
    this.enviadas = const [],
  });

  final String miCodigo;
  final List<PersonaAmistad> amistades;
  final List<PersonaAmistad> recibidas;
  final List<PersonaAmistad> enviadas;

  factory AmistadesData.fromJson(Map<String, dynamic> json) {
    List<PersonaAmistad> lista(String clave) => (json[clave] as List? ?? [])
        .whereType<Map>()
        .map((e) => PersonaAmistad.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return AmistadesData(
      miCodigo: json['miCodigo']?.toString() ?? '',
      amistades: lista('amistades'),
      recibidas: lista('recibidas'),
      enviadas: lista('enviadas'),
    );
  }
}

/// Respuesta de una acción de amistad: si salió bien y el mensaje para la persona.
class ResultadoAmistad {
  const ResultadoAmistad({required this.ok, this.mensaje = '', this.estado});

  final bool ok;
  final String mensaje;
  final EstadoAmistad? estado;
}
