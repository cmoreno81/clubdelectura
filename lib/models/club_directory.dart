/// Un club público listado en el directorio, antes de unirse.
class ClubPublico {
  final String clubId;
  final String nombre;
  final String slug;
  final String? descripcion;
  final String? avatarUrl;
  final int miembros;

  const ClubPublico({
    required this.clubId,
    required this.nombre,
    required this.slug,
    required this.descripcion,
    required this.avatarUrl,
    required this.miembros,
  });

  factory ClubPublico.fromJson(Map<String, dynamic> json) {
    return ClubPublico(
      clubId: json['clubId'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      miembros: (json['miembros'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Una solicitud pendiente de ingreso a un club, vista por quien administra.
class SolicitudClub {
  final String id;
  final String userId;
  final String nombre;
  final String? avatarUrl;
  final DateTime solicitadoEn;

  const SolicitudClub({
    required this.id,
    required this.userId,
    required this.nombre,
    required this.avatarUrl,
    required this.solicitadoEn,
  });

  factory SolicitudClub.fromJson(Map<String, dynamic> json) {
    return SolicitudClub(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      solicitadoEn:
          DateTime.tryParse(json['solicitadoEn'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
