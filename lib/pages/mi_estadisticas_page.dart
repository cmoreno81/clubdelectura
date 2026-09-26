import 'package:flutter/material.dart';

import '../models/estadisticas_personales.dart';
import '../models/general_dashboard.dart';
import '../services/api_service.dart';
import '../services/general_dashboard_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/mapa_calor_widget.dart';
import 'dashboard_page.dart' show AchievementsClubCard, LogrosClubCard;

/// "Mis estadísticas": todo lo que es dato puro sobre tu lectura — mapa de
/// calor, métricas del año, ritmo de lectura, géneros, reto lector y logros,
/// y los superlativos del año (libro más largo, lectura más rápida).
/// Disponible tanto en el espacio personal como en cuentas de club, porque
/// son datos tuyos como lectora, no del club.
class MiEstadisticasPage extends StatefulWidget {
  const MiEstadisticasPage({super.key});

  @override
  State<MiEstadisticasPage> createState() => _MiEstadisticasPageState();
}

class _MiEstadisticasPageState extends State<MiEstadisticasPage> {
  late Future<_PageData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_PageData> _load() async {
    final results = await Future.wait([
      GeneralDashboardService().load(),
      ApiService()
          .getEstadisticasPersonales()
          .then(EstadisticasPersonales.fromJson),
    ]);
    return _PageData(
      dashboard: results[0] as GeneralDashboard,
      estadisticas: results[1] as EstadisticasPersonales,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis estadísticas')),
      body: FutureBuilder<_PageData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return _ErrorView(onRetry: () => setState(() => _future = _load()));
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: _Content(data: snapshot.data!),
          );
        },
      ),
    );
  }
}

class _PageData {
  const _PageData({required this.dashboard, required this.estadisticas});
  final GeneralDashboard dashboard;
  final EstadisticasPersonales estadisticas;
}

class _Content extends StatelessWidget {
  const _Content({required this.data});
  final _PageData data;

  @override
  Widget build(BuildContext context) {
    final summary = data.dashboard.summary;
    final ritmo = data.estadisticas.ritmo;
    final generos = data.estadisticas.generos;
    final libroMasLargo = data.estadisticas.libroMasLargo;
    final lecturaMasRapida = data.estadisticas.lecturaMasRapida;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxxl,
      ),
      children: [
        // ── Mapa de calor ────────────────────────────────────────────────
        const ClubCard(child: MapaCalorWidget()),
        const SizedBox(height: AppSpacing.lg),

        // ── Cuadrícula de métricas ───────────────────────────────────────
        _StatsGrid(summary: summary),
        const SizedBox(height: AppSpacing.lg),

        // ── Ritmo de lectura ─────────────────────────────────────────────
        _RitmoLecturaCard(ritmo: ritmo),
        const SizedBox(height: AppSpacing.md),

        // ── Géneros del año ──────────────────────────────────────────────
        if (generos.isNotEmpty) ...[
          _GenerosCard(generos: generos),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Reto lector + logros ─────────────────────────────────────────
        const LogrosClubCard(esPersonal: true),
        const SizedBox(height: AppSpacing.sm),
        const AchievementsClubCard(esPersonal: true),
        const SizedBox(height: AppSpacing.md),

        // ── Superlativos del año ─────────────────────────────────────────
        if (libroMasLargo != null || lecturaMasRapida != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (libroMasLargo != null)
                Expanded(
                  child: _SuperlativoCard(
                    eyebrow: 'Libro más largo',
                    titulo: libroMasLargo.titulo,
                    detalle: libroMasLargo.paginas != null
                        ? '${libroMasLargo.paginas} páginas'
                        : null,
                  ),
                ),
              if (libroMasLargo != null && lecturaMasRapida != null)
                const SizedBox(width: AppSpacing.sm),
              if (lecturaMasRapida != null)
                Expanded(
                  child: _SuperlativoCard(
                    eyebrow: 'Lectura más rápida',
                    titulo: lecturaMasRapida.titulo,
                    detalle: lecturaMasRapida.dias == 0
                        ? 'Terminado en 1 día'
                        : 'Terminado en ${lecturaMasRapida.dias} días',
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _StatsGrid
// ────────────────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.summary});
  final GeneralSummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2,
      children: [
        _StatCard(
          value: '${summary.reading}',
          label: 'Leyendo ahora',
          icon: Icons.menu_book_rounded,
          color: AppColors.info,
        ),
        _StatCard(
          value: '${summary.finished}',
          label: 'Terminados',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        ),
        _StatCard(
          value: '${summary.finishedThisMonth}',
          label: 'Este mes',
          icon: Icons.bolt_rounded,
          color: AppColors.warning,
        ),
        _StatCard(
          value: '${summary.pagesRead}',
          label: 'Páginas leídas',
          icon: Icons.bookmark_rounded,
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: .14),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _RitmoLecturaCard
// ────────────────────────────────────────────────────────────────────────────

class _RitmoLecturaCard extends StatelessWidget {
  const _RitmoLecturaCard({required this.ritmo});
  final RitmoLectura ritmo;

  @override
  Widget build(BuildContext context) {
    final maxVal = ritmo.serie.isEmpty
        ? 1
        : ritmo.serie.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);
    final variacion = ritmo.variacionPct;

    return ClubCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tu ritmo de lectura',
                style: AppTextStyles.subtitle.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (variacion != null)
                Text(
                  '${variacion >= 0 ? '▲' : '▼'} ${variacion.abs()}% vs. mes pasado',
                  style: AppTextStyles.caption.copyWith(
                    color: variacion >= 0 ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (ritmo.serie.isNotEmpty)
            SizedBox(
              height: 44,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < ritmo.serie.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: FractionallySizedBox(
                          heightFactor: ritmo.serie[i] / maxVal,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: i == ritmo.serie.length - 1
                                  ? AppColors.primary
                                  : AppColors.primaryLight,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Media de ${ritmo.paginasPorDiaMes.toStringAsFixed(0)} páginas al día este mes',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _GenerosCard
// ────────────────────────────────────────────────────────────────────────────

class _GenerosCard extends StatelessWidget {
  const _GenerosCard({required this.generos});
  final List<GeneroLectura> generos;

  static const _colores = [AppColors.primary, AppColors.gold, AppColors.info];

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tus géneros de ${DateTime.now().year}',
            style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < generos.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      generos[i].nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: generos[i].porcentaje / 100,
                        minHeight: 8,
                        backgroundColor: AppColors.background,
                        color: _colores[i % _colores.length],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${generos[i].porcentaje}%',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _SuperlativoCard
// ────────────────────────────────────────────────────────────────────────────

class _SuperlativoCard extends StatelessWidget {
  const _SuperlativoCard({
    required this.eyebrow,
    required this.titulo,
    this.detalle,
  });

  final String eyebrow;
  final String titulo;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          if (detalle != null) ...[
            const SizedBox(height: 2),
            Text(
              detalle!,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _ErrorView
// ────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48),
          const SizedBox(height: 12),
          const Text('No pudimos cargar tus estadísticas.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
