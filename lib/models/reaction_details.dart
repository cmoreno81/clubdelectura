class ReactionDetails {
  final int total;
  final List<ReactionGroup> grupos;

  const ReactionDetails({required this.total, required this.grupos});

  factory ReactionDetails.fromJson(Map<String, dynamic> json) =>
      ReactionDetails(
        total: (json['total'] as num?)?.toInt() ?? 0,
        grupos: (json['grupos'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) => ReactionGroup.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false),
      );

  List<ReactionUser> get usuarios =>
      grupos.expand((grupo) => grupo.usuarios).toList(growable: false)
        ..sort((a, b) {
          final byDate = a.fecha.compareTo(b.fecha);
          return byDate != 0 ? byDate : a.id.compareTo(b.id);
        });
}

class ReactionGroup {
  final String reaccion;
  final List<ReactionUser> usuarios;

  const ReactionGroup({required this.reaccion, required this.usuarios});

  factory ReactionGroup.fromJson(Map<String, dynamic> json) => ReactionGroup(
    reaccion: json['reaccion']?.toString() ?? '',
    usuarios: (json['usuarios'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => ReactionUser.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false),
  );
}

class ReactionUser {
  final String id;
  final String nombre;
  final String avatarUrl;
  final bool esTu;
  final DateTime fecha;

  const ReactionUser({
    required this.id,
    required this.nombre,
    required this.avatarUrl,
    required this.esTu,
    required this.fecha,
  });

  factory ReactionUser.fromJson(Map<String, dynamic> json) => ReactionUser(
    id: json['id']?.toString() ?? '',
    nombre: json['nombre']?.toString() ?? '',
    avatarUrl: json['avatarUrl']?.toString() ?? '',
    esTu: json['esTu'] == true,
    fecha:
        DateTime.tryParse(json['fecha']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );
}
