import 'candidata_clubvision.dart';

class ClubvisionData {
  final bool abierta;

  final String? estado;

  final String idVotacion;

  final String titulo;

  final String mensaje;

  final String ganador;

  final bool lecturaConfigurada;

  final List<String> lectoras;

  final List<CandidataClubvision> candidatas;

  final bool haVotado;

  final bool esAdmin;
  final String tipo;
  final ClubvisionWelcomeEligibility bienvenida;

  final int votosRecibidos;

  final int totalUsuarios;

  final int votosPendientes;

  final int porcentaje;

  ClubvisionData({
    required this.abierta,
    this.estado,
    required this.idVotacion,
    required this.titulo,
    required this.mensaje,
    required this.ganador,
    required this.lecturaConfigurada,
    required this.lectoras,
    required this.candidatas,
    required this.haVotado,
    this.esAdmin = false,
    this.tipo = 'MONTHLY',
    this.bienvenida = const ClubvisionWelcomeEligibility(),
    required this.votosRecibidos,
    required this.totalUsuarios,
    required this.votosPendientes,
    required this.porcentaje,
  });

  factory ClubvisionData.fromJson(Map<String, dynamic> json) {
    return ClubvisionData(
      abierta: json['abierta'] ?? false,
      estado: json['estado'],

      idVotacion: json['idVotacion'] ?? '',

      titulo: json['titulo'] ?? '',

      mensaje: json['mensaje'] ?? '',

      ganador: json['ganador'] ?? '',

      lecturaConfigurada: json['lecturaConfigurada'] == true,

      lectoras: List<String>.from(json['lectoras'] ?? []),

      candidatas:
          (json['candidatas'] as List?)
              ?.map((e) => CandidataClubvision.fromJson(e))
              .toList() ??
          [],
      haVotado: json['haVotado'] ?? false,
      esAdmin: json['esAdmin'] == true,
      tipo: json['tipo']?.toString() ?? 'MONTHLY',
      bienvenida: ClubvisionWelcomeEligibility.fromJson(json['bienvenida']),
      votosRecibidos: (json['votosRecibidos'] as num?)?.toInt() ?? 0,

      totalUsuarios: (json['totalUsuarios'] as num?)?.toInt() ?? 0,

      votosPendientes: (json['votosPendientes'] as num?)?.toInt() ?? 0,

      porcentaje: (json['porcentaje'] as num?)?.toInt() ?? 0,
    );
  }
}

class ClubvisionWelcomeEligibility {
  const ClubvisionWelcomeEligibility({
    this.disponible = false,
    this.esAdmin = false,
    this.miembros = 0,
    this.candidatas = 0,
    this.minimoMiembros = 3,
    this.minimoCandidatas = 5,
    this.motivo = '',
  });

  final bool disponible;
  final bool esAdmin;
  final int miembros;
  final int candidatas;
  final int minimoMiembros;
  final int minimoCandidatas;
  final String motivo;

  factory ClubvisionWelcomeEligibility.fromJson(dynamic value) {
    if (value is! Map) return const ClubvisionWelcomeEligibility();
    return ClubvisionWelcomeEligibility(
      disponible: value['disponible'] == true,
      esAdmin: value['esAdmin'] == true,
      miembros: (value['miembros'] as num?)?.toInt() ?? 0,
      candidatas: (value['candidatas'] as num?)?.toInt() ?? 0,
      minimoMiembros: (value['minimoMiembros'] as num?)?.toInt() ?? 3,
      minimoCandidatas: (value['minimoCandidatas'] as num?)?.toInt() ?? 5,
      motivo: value['motivo']?.toString() ?? '',
    );
  }
}
