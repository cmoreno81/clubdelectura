class ClubMembership {
  const ClubMembership({
    required this.id,
    required this.nombre,
    required this.slug,
    required this.rol,
    required this.activo,
    this.descripcion = '',
    this.avatarUrl = '',
  });

  final String id;
  final String nombre;
  final String slug;
  final String rol;
  final bool activo;
  final String descripcion;
  final String avatarUrl;

  factory ClubMembership.fromJson(Map<String, dynamic> json) => ClubMembership(
    id: json['id']?.toString() ?? '',
    nombre: json['nombre']?.toString() ?? '',
    slug: json['slug']?.toString() ?? '',
    rol: json['rol']?.toString() ?? 'MEMBER',
    activo: json['activo'] == true,
    descripcion: json['descripcion']?.toString() ?? '',
    avatarUrl: json['avatarUrl']?.toString() ?? '',
  );
}

class MyClubs {
  const MyClubs({required this.clubs, this.activeClubId});

  final List<ClubMembership> clubs;
  final String? activeClubId;

  factory MyClubs.fromJson(Map<String, dynamic> json) => MyClubs(
    activeClubId: json['activeClubId']?.toString(),
    clubs: (json['clubs'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              ClubMembership.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false),
  );
}
