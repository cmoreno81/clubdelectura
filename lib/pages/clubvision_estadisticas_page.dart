import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/clubvision_estadisticas.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_shimmer.dart';
import '../widgets/error_view.dart';

class ClubvisionEstadisticasPage extends StatefulWidget {
  const ClubvisionEstadisticasPage({super.key});

  @override
  State<ClubvisionEstadisticasPage> createState() =>
      _ClubvisionEstadisticasPageState();
}

class _ClubvisionEstadisticasPageState
    extends State<ClubvisionEstadisticasPage> {
  late Future<ClubvisionEstadisticas> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService().getClubvisionEstadisticas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: FutureBuilder<ClubvisionEstadisticas>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const CardListSkeleton();
          }
          if (snap.hasError || snap.data == null) {
            return ErrorView(onRetry: () => setState(() {
              _future = ApiService().getClubvisionEstadisticas();
            }));
          }
          final stats = snap.data!;
          if (stats.totalEdiciones == 0) {
            return _EmptyStats();
          }
          return _StatsBody(stats: stats);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cuerpo principal
// ─────────────────────────────────────────────────────────────────────────────

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});
  final ClubvisionEstadisticas stats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        110,
      ),
      children: [
        // ── Cabecera con totales ───────────────────────────────────────────
        _HeaderCards(stats: stats),

        const SizedBox(height: AppSpacing.xl),

        // ── Podio: récords del club ────────────────────────────────────────
        if (stats.ganadores.length >= 2) ...[
          _SectionLabel(label: 'Récords del club', icon: '🏆'),
          const SizedBox(height: AppSpacing.md),
          _RecordsPodio(stats: stats),
          const SizedBox(height: AppSpacing.xl),
        ],

        // ── Por edición: lectoras ──────────────────────────────────────────
        _SectionLabel(label: 'Lectoras por edición', icon: '📚'),
        const SizedBox(height: AppSpacing.md),
        _LectorasChart(ganadores: stats.ganadores),

        const SizedBox(height: AppSpacing.xl),

        // ── Por edición: tarjetas detalle ─────────────────────────────────
        _SectionLabel(label: 'Detalle por edición', icon: '📊'),
        const SizedBox(height: AppSpacing.md),
        ...stats.ganadores.map((g) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _EdicionCard(ganador: g),
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header: totales globales
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderCards extends StatelessWidget {
  const _HeaderCards({required this.stats});
  final ClubvisionEstadisticas stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF25162F), Color(0xFF5E347C), Color(0xFF8C527E)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          _HeaderStat(
            value: '${stats.totalEdiciones}',
            label: 'Ediciones',
            icon: '🗓️',
          ),
          _VerticalDivider(),
          _HeaderStat(
            value: '${stats.totalMiembros}',
            label: 'Miembros',
            icon: '👥',
          ),
          _VerticalDivider(),
          _HeaderStat(
            value: '${stats.participacionMedia}',
            label: 'Votos/edición',
            icon: '🗳️',
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .70),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 50,
        color: Colors.white.withValues(alpha: .20),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Récords del club (podio visual)
// ─────────────────────────────────────────────────────────────────────────────

class _RecordsPodio extends StatelessWidget {
  const _RecordsPodio({required this.stats});
  final ClubvisionEstadisticas stats;

  @override
  Widget build(BuildContext context) {
    final masLeido = stats.masLeido;
    final mejorValorado = stats.mejorValorado;
    final masComentado = stats.masComentado;

    return Column(
      children: [
        if (masLeido != null)
          _RecordTile(
            emoji: '📖',
            label: 'Más leído',
            titulo: masLeido.titulo,
            coverUrl: masLeido.coverUrl,
            detalle: '${masLeido.lectoras} de ${masLeido.totalMiembros} lectoras',
            color: const Color(0xFF4A9E4A),
          ),
        if (mejorValorado != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _RecordTile(
            emoji: '⭐',
            label: 'Mejor valorado',
            titulo: mejorValorado.titulo,
            coverUrl: mejorValorado.coverUrl,
            detalle: '${mejorValorado.valoracionMedia!.toStringAsFixed(1)} / 5',
            color: const Color(0xFFB48113),
          ),
        ],
        if (masComentado != null && masComentado.totalComentarios > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          _RecordTile(
            emoji: '💬',
            label: 'Más comentado',
            titulo: masComentado.titulo,
            coverUrl: masComentado.coverUrl,
            detalle: '${masComentado.totalComentarios} comentarios',
            color: const Color(0xFF4A6FBF),
          ),
        ],
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.emoji,
    required this.label,
    required this.titulo,
    required this.coverUrl,
    required this.detalle,
    required this.color,
  });

  final String emoji;
  final String label;
  final String titulo;
  final String coverUrl;
  final String detalle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          // Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: ClubBookCover(
              title: titulo,
              imageUrl: coverUrl.isEmpty ? null : coverUrl,
              width: 46,
              height: 64,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji,
                              style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detalle,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

// ─────────────────────────────────────────────────────────────────────────────
// Gráfico de barras: lectoras por edición
// ─────────────────────────────────────────────────────────────────────────────

class _LectorasChart extends StatelessWidget {
  const _LectorasChart({required this.ganadores});
  final List<ClubvisionGanadorStats> ganadores;

  @override
  Widget build(BuildContext context) {
    // Mostrar máximo las últimas 8 ediciones para que quepan bien
    final lista = ganadores.take(8).toList();
    final maxVal =
        lista.map((g) => g.lectoras).fold(0, (a, b) => math.max(a, b));

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
          // Leyenda
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Lectoras que lo terminaron',
                style: AppTextStyles.caption,
              ),
              const Spacer(),
              Text(
                'de ${ganadores.isNotEmpty ? ganadores.first.totalMiembros : 0} miembros',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Barras
          ...lista.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BarRow(
                  ganador: g,
                  maxVal: maxVal == 0 ? 1 : maxVal,
                ),
              )),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.ganador, required this.maxVal});
  final ClubvisionGanadorStats ganador;
  final int maxVal;

  @override
  Widget build(BuildContext context) {
    final ratio = ganador.lectoras / maxVal;
    // Mes legible: "2025-03" → "Mar 25"
    final parts = ganador.edition.split('-');
    final mes = parts.length == 2
        ? '${_mesCorto(int.tryParse(parts[1]) ?? 0)} ${parts[0].substring(2)}'
        : ganador.edition;

    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            mes,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth * ratio;
              return Stack(
                children: [
                  // Fondo
                  Container(
                    height: 22,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  // Barra
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: 22,
                    width: math.max(barWidth, ganador.lectoras > 0 ? 22 : 0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          const Color(0xFF8C527E),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  // Número dentro o fuera
                  Positioned.fill(
                    child: Align(
                      alignment: barWidth > 30
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${ganador.lectoras}',
                          style: TextStyle(
                            color: barWidth > 30
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 34,
          child: Text(
            '${(ganador.porcentajeLectoras * 100).round()}%',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _mesCorto(int mes) => const [
        '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
      ][mes.clamp(0, 12)];
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta detalle por edición
// ─────────────────────────────────────────────────────────────────────────────

class _EdicionCard extends StatelessWidget {
  const _EdicionCard({required this.ganador});
  final ClubvisionGanadorStats ganador;

  @override
  Widget build(BuildContext context) {
    final parts = ganador.edition.split('-');
    final edicionLabel = parts.length == 2
        ? '${_mesCompleto(int.tryParse(parts[1]) ?? 0)} ${parts[0]}'
        : ganador.edition;

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
          // ── Cabecera: portada + título + edición ────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: ClubBookCover(
                  title: ganador.titulo,
                  imageUrl: ganador.coverUrl.isEmpty ? null : ganador.coverUrl,
                  width: 52,
                  height: 72,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      edicionLabel,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ganador.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Puntos de votación
                    _Pill(
                      icon: Icons.how_to_vote_outlined,
                      label: '${ganador.puntos} puntos · ${ganador.votantes} votantes',
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),

          // ── Métricas ────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MetricaCol(
                  icon: '📖',
                  valor: '${ganador.lectoras}/${ganador.totalMiembros}',
                  label: 'Lo leyeron',
                  subValor: '${(ganador.porcentajeLectoras * 100).round()}%',
                  color: const Color(0xFF4A9E4A),
                ),
              ),
              if (ganador.valoracionMedia != null) ...[
                _ColumnDivider(),
                Expanded(
                  child: _MetricaCol(
                    icon: '⭐',
                    valor: ganador.valoracionMedia!.toStringAsFixed(1),
                    label: 'Valoración',
                    subValor: 'sobre 5',
                    color: const Color(0xFFB48113),
                  ),
                ),
              ],
              if (ganador.totalComentarios > 0) ...[
                _ColumnDivider(),
                Expanded(
                  child: _MetricaCol(
                    icon: '💬',
                    valor: '${ganador.totalComentarios}',
                    label: 'Comentarios',
                    color: const Color(0xFF4A6FBF),
                  ),
                ),
              ],
            ],
          ),

          // ── Barra de lectura ────────────────────────────────────────────
          if (ganador.totalMiembros > 0) ...[
            const SizedBox(height: AppSpacing.md),
            _LecturaProgressBar(ganador: ganador),
          ],
        ],
      ),
    );
  }

  String _mesCompleto(int mes) => const [
        '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
      ][mes.clamp(0, 12)];
}

class _LecturaProgressBar extends StatelessWidget {
  const _LecturaProgressBar({required this.ganador});
  final ClubvisionGanadorStats ganador;

  @override
  Widget build(BuildContext context) {
    final pct = ganador.porcentajeLectoras;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppColors.surfaceMuted,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF4A9E4A)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${ganador.lectoras} de ${ganador.totalMiembros} miembros lo terminaron',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricaCol extends StatelessWidget {
  const _MetricaCol({
    required this.icon,
    required this.valor,
    required this.label,
    required this.color,
    this.subValor,
  });
  final String icon;
  final String valor;
  final String label;
  final Color color;
  final String? subValor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 3),
        Text(
          valor,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -.3,
          ),
        ),
        if (subValor != null)
          Text(
            subValor!,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ColumnDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 50,
        color: AppColors.border,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.icon});
  final String label;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _EmptyStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📊', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aún no hay ediciones completadas',
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Las estadísticas aparecerán cuando el club\ncomplete su primera Clubvisión.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
