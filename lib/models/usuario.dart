class Usuario {

  final String nombre;

  final String email;

  Usuario({

    required this.nombre,

    required this.email,
  });

  factory Usuario.fromJson(
    Map<String, dynamic> json,
  ) {

    return Usuario(

      nombre:
          json["nombre"] ?? "",

      email:
          json["email"] ?? "",
    );
  }
}