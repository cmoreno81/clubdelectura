class AuthUser {
  const AuthUser({
    required this.id,
    required this.nombre,
    required this.email,
    this.avatarUrl = '',
  });

  final String id;
  final String nombre;
  final String email;
  final String avatarUrl;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id']?.toString() ?? '',
    nombre: json['nombre']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    avatarUrl: json['avatarUrl']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'email': email,
    'avatarUrl': avatarUrl,
  };
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;
}
