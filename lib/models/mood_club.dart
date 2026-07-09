class MoodClub {
  final String titular;
  final String narrador;
  final List<String> estados;
  final List<ActividadClub> actividad;

  MoodClub({
    required this.titular,
    required this.narrador,
    required this.estados,
    required this.actividad,
  });

  factory MoodClub.fromJson(Map<String, dynamic> json) {
    return MoodClub(
      titular: json['titular'],
      narrador: json['narrador'],
      estados: List<String>.from(json['estados']),
      actividad: (json['actividad'] as List)
          .map((e) => ActividadClub.fromJson(e))
          .toList(),
    );
  }
}

class ActividadClub {
  final String icono;
  final String texto;

  ActividadClub({required this.icono, required this.texto});

  factory ActividadClub.fromJson(Map<String, dynamic> json) {
    return ActividadClub(icono: json['icono'], texto: json['texto']);
  }
}
