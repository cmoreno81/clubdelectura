class LectorFinalizado {
  final String usuario;
  final String valoracion;

  LectorFinalizado({required this.usuario, required this.valoracion});

  factory LectorFinalizado.fromJson(Map<String, dynamic> json) {
    return LectorFinalizado(
      usuario: json["usuario"] ?? "",
      valoracion: json["valoracion"] ?? "",
    );
  }
}
