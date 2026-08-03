class SagaOculta {
  const SagaOculta({required this.id, required this.nombre});

  final String id;
  final String nombre;

  factory SagaOculta.fromJson(Map<String, dynamic> json) => SagaOculta(
    id: json['id']?.toString() ?? json['sagaId']?.toString() ?? '',
    nombre: json['nombre']?.toString() ?? json['name']?.toString() ?? '',
  );
}
