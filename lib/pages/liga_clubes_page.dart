import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/error_view.dart';

class FilaClub {
  final String clubId;
  final String nombre;
  final String? avatarUrl;
  final int totalPoints;
  final int activeMembers;
  final double avgPoints;
  final int puesto;

  const FilaClub({
    required this.clubId,
    required this.nombre,
    required this.avatarUrl,
    required this.totalPoints,
    required this.activeMembers,
    required this.avgPoints,
    required this.puesto,
  });

  factory FilaClub.fromJson(Map<String, dynamic> json) {
    return FilaClub(
      clubId: json['clubId'] as String? ?? '',
      nombre: json['nombre'] as String? ?? 'Club',
      avatarUrl: json['avatarUrl'] as String?,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      activeMembers: (json['activeMembers'] as num?)?.toInt() ?? 0,
      avgPoints: (json['avgPoints'] as num?)?.toDouble() ?? 0,
      puesto: (json['puesto'] as num?)?.toInt() ?? 0,
    );
  }
}

class LigaClubesEstado {
  final int season;
  final List<FilaClub> masActivos;
  final List<FilaClub> masEficientes;

  const LigaClubesEstado({
    required this.season,
    required this.masActivos,
    required this.masEficientes,
  });

  factory LigaClubesEstado.fromJson(Map<String, dynamic> json) {
    return LigaClubesEstado(
      season: (json['season'] as num?)?.toInt() ?? 0,
      masActivos: (json['masActivos'] as List<dynamic>? ?? [])
          .map((e) => FilaClub.fromJson(e as Map<String, dynamic>))
          .toList(),
      masEficientes: (json['masEficientes'] as List<dynamic>? ?? [])
          .map((e) => FilaClub.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Ligas entre clubes: dos rankings del mismo dato — "más activos" (suma
/// total de puntos de sus miembros) y "más eficientes" (media por miembro
/// participante), para que un club pequeño y constante también pueda ganar.
class LigaClubesPage extends StatefulWidget {
  const LigaClubesPage({super.key});

  @override
  State<LigaClubesPage> createState() => _LigaClubesPageState();
}

class _LigaClubesPageState extends State<LigaClubesPage> {
  late Future<LigaClubesEstado> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<LigaClubesEstado> _cargar() async {
    final json = await ApiService().getLigaClubes();
    return LigaClubesEstado.fromJson(json);
  }

  void _recargar() => setState(() => _future = _cargar());

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ligas entre clubes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Más activos'),
              Tab(text: 'Más eficientes'),
            ],
          ),
        ),
        body: FutureBuilder<LigaClubesEstado>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorView(onRetry: _recargar);
            }
            final estado = snapshot.data!;
            return TabBarView(
              children: [
                _TablaClubes(
                  filas: estado.masActivos,
                  metrica: _Metrica.total,
                  cabecera:
                      'Suma de los puntos de todas las participantes del club. Premia el volumen — cuantas más lectoras activas, más arriba.',
                  onRefresh: () async => _recargar(),
                ),
                _TablaClubes(
                  filas: estado.masEficientes,
                  metrica: _Metrica.media,
                  cabecera:
                      'Puntos por miembro participante. El ranking justo: un club pequeño y constante puede ganar a uno grande y disperso.',
                  onRefresh: () async => _recargar(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _Metrica { total, media }

class _TablaClubes extends StatelessWidget {
  final List<FilaClub> filas;
  final _Metrica metrica;
  final String cabecera;
  final Future<void> Function() onRefresh;

  const _TablaClubes({
    required this.filas,
    required this.metrica,
    required this.cabecera,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (filas.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.6,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    metrica == _Metrica.media
                        ? 'Todavía no hay clubes con suficientes miembros participando en Ligas.'
                        : 'Todavía no hay clubes participando en Ligas.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          40,
        ),
        itemCount: filas.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                cabecera,
                style: AppTextStyles.bodySecondary.copyWith(height: 1.35),
              ),
            );
          }
          final fila = filas[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _FilaClub(fila: fila, metrica: metrica),
          );
        },
      ),
    );
  }
}

class _FilaClub extends StatelessWidget {
  final FilaClub fila;
  final _Metrica metrica;

  const _FilaClub({required this.fila, required this.metrica});

  @override
  Widget build(BuildContext context) {
    final podio = fila.puesto <= 3;
    final colorPodio = switch (fila.puesto) {
      1 => const Color(0xFFD5A94E),
      2 => const Color(0xFF9AA3AF),
      3 => const Color(0xFFB77948),
      _ => AppColors.primary,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: podio
            ? colorPodio.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: podio
              ? colorPodio.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${fila.puesto}',
              textAlign: TextAlign.center,
              style: AppTextStyles.section.copyWith(
                color: podio ? colorPodio : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ClubAvatar(nombre: fila.nombre, imageUrl: fila.avatarUrl, size: 44),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fila.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${fila.activeMembers} ${fila.activeMembers == 1 ? 'participante' : 'participantes'}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                metrica == _Metrica.total
                    ? '${fila.totalPoints}'
                    : fila.avgPoints.toStringAsFixed(1),
                style: AppTextStyles.section.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                metrica == _Metrica.total ? 'puntos' : 'media',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
