class ProgresoLecturaResult {
  const ProgresoLecturaResult({
    required this.ok,
    required this.mensaje,
    this.progreso,
    this.paginaActual,
  });

  final bool ok;
  final String mensaje;
  final int? progreso;
  final int? paginaActual;

  factory ProgresoLecturaResult.fromJson(Map<String, dynamic> json) {
    return ProgresoLecturaResult(
      ok: json['ok'] == true,
      mensaje: json['mensaje']?.toString() ?? '',
      progreso: (json['progreso'] as num?)?.toInt(),
      paginaActual: (json['paginaActual'] as num?)?.toInt(),
    );
  }

  factory ProgresoLecturaResult.error(String mensaje) =>
      ProgresoLecturaResult(ok: false, mensaje: mensaje);
}
