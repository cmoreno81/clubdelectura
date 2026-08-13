enum TipoClub { social, personal }

class ClubMembership {
  const ClubMembership({
    required this.id,
    required this.nombre,
    required this.slug,
    required this.rol,
    required this.activo,
    this.descripcion = '',
    this.avatarUrl = '',
    this.tipo = TipoClub.social,
  });

  final String id;
  final String nombre;
  final String slug;
  final String rol;
  final bool activo;
  final String descripcion;
  final String avatarUrl;
  final TipoClub tipo;

  /// Espacio lector personal (modo solitario).
  bool get esPersonal => tipo == TipoClub.personal;

  factory ClubMembership.fromJson(Map<String, dynamic> json) => ClubMembership(
    id: json['id']?.toString() ?? '',
    nombre: json['nombre']?.toString() ?? '',
    slug: json['slug']?.toString() ?? '',
    rol: json['rol']?.toString() ?? 'MEMBER',
    activo: json['activo'] == true,
    descripcion: json['descripcion']?.toString() ?? '',
    avatarUrl: json['avatarUrl']?.toString() ?? '',
    tipo: json['tipo']?.toString() == 'PERSONAL'
        ? TipoClub.personal
        : TipoClub.social,
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

class ClubMember {
  const ClubMember({
    required this.id,
    required this.nombre,
    required this.avatarUrl,
    required this.rol,
    required this.desde,
  });

  final String id;
  final String nombre;
  final String avatarUrl;
  final String rol;
  final String desde;

  bool get esOwner => rol == 'OWNER';
  bool get esAdmin => rol == 'ADMIN' || rol == 'OWNER';

  factory ClubMember.fromJson(Map<String, dynamic> json) => ClubMember(
    id: json['id']?.toString() ?? '',
    nombre: json['nombre']?.toString() ?? '',
    avatarUrl: json['avatarUrl']?.toString() ?? '',
    rol: json['rol']?.toString() ?? 'MEMBER',
    desde: json['desde']?.toString() ?? '',
  );
}
