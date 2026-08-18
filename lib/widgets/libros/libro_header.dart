import 'package:flutter/material.dart';

import '../../models/libro.dart';
import '../../models/libro_agrupado.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/genero_utils.dart';
import '../../utils/lector_count_utils.dart';
import '../../utils/reading_status_copy.dart';
import '../common/club_book_cover.dart';
import '../common/club_card.dart';
import '../ui/club_metric.dart';
import '../ui/club_section_card.dart';

class LibroHeader extends StatelessWidget {
  final LibroAgrupado libro;
  final Libro? referencia;
  final VoidCallback? onAbrirGoodreads;

  /// Tag Hero de la portada; debe coincidir con el usado en la lista de origen.
  final String? heroTag;

  /// Cuando es `true` (vista global), oculta los chips de contadores y media
  /// que ya aparecen en la sección de estadísticas, y muestra en su lugar
  /// el estado personal del usuario si [miEstado] está disponible.
  final bool globalStats;

  /// Estado de lectura del usuario actual (solo relevante cuando
  /// [globalStats] = true). `null` si el libro no está en su biblioteca.
  /// Puede venir de `registros` (ej. 'PENDIENTE', 'LEYENDO') o de
  /// `finalizados` (siempre 'FINALIZADO').
  final String? miEstado;

  const LibroHeader({
    super.key,
    required this.libro,
    required this.referencia,
    this.onAbrirGoodreads,
    this.heroTag,
    this.globalStats = false,
    this.miEstado,
  });

  @override
  Widget build(BuildContext context) {
    final tieneGoodreads = libro.goodreads.isNotEmpty;

    return Column(
      children: [
        ClubCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surfaceSoft, Color(0xFFF0E5FF)],
          ),
          borderColor: AppColors.primaryLight,
          child: Column(
            children: [
              ClubBookCover(
                title: libro.libro,
                imageUrl: libro.coverUrl,
                width: 184,
                highResolution: true,
                showShadow: true,
                heroTag: heroTag,
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                libro.libro,
                textAlign: TextAlign.center,
                style: AppTextStyles.title.copyWith(fontSize: 28, height: 1.15),
              ),

              if (referencia?.autor.trim().isNotEmpty ?? false) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  referencia!.autor.trim(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.sm),

              Text(
                '${iconoGenero(libro.genero)} ${libro.genero}',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              _metadatosLibro(),

              if (referencia?.paginas != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${referencia!.paginas} páginas',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              if (globalStats)
                // Vista global: solo mostramos el estado personal del usuario.
                // Los contadores y la media ya están en _EstadisticasGlobalesSection.
                _EstadoPersonalChip(estado: miEstado)
              else ...[
                // Vista de club: métricas completas de contadores y valoración.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final apilar = constraints.maxWidth < 360 || textScale > 1.2;
                    final metricas = [
                      ClubMetric(
                        icon: Icons.people_outline_rounded,
                        value: '${libro.total}',
                        label: lectoresInteresadosLabel(libro.total),
                        variant: ClubMetricVariant.info,
                        compact: true,
                      ),
                      ClubMetric(
                        icon: Icons.check_circle_outline_rounded,
                        value: '${libro.totalFinalizados}',
                        label: librosLeidosLabel(libro.totalFinalizados),
                        variant: ClubMetricVariant.success,
                        compact: true,
                      ),
                    ];

                    if (apilar) {
                      return Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        alignment: WrapAlignment.center,
                        children: metricas,
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: metricas[0]),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: metricas[1]),
                      ],
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.sm),

                ClubMetric(
                  icon: Icons.star_outline_rounded,
                  value: libro.mediaValoracion > 0
                      ? libro.mediaValoracion.toStringAsFixed(1)
                      : '—',
                  label: 'valoración media',
                  variant: ClubMetricVariant.warning,
                ),
              ],
            ],
          ),
        ),

        if (tieneGoodreads) ...[
          const SizedBox(height: AppSpacing.md),

          ClubSectionCard(
            onTap: onAbrirGoodreads,
            backgroundColor: const Color(0xFFFFF9EA),
            borderColor: const Color(0xFFF1E2B3),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDBA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.open_in_new_rounded,
                    color: Color(0xFFB48113),
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ver ficha en Goodreads',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      Text(
                        'Sinopsis, opiniones y valoraciones',
                        style: AppTextStyles.bodySecondary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB48113),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _metadatosLibro() {
    if (referencia == null) {
      return const SizedBox.shrink();
    }

    if (referencia!.autoconclusivo == 'Si') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_stories_outlined,
            size: 18,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: AppSpacing.xs),
          Text('Autoconclusivo', style: AppTextStyles.bodySecondary),
        ],
      );
    }

    final saga = referencia!.saga.trim();
    final numeroSaga = referencia!.numSaga.trim();

    return Column(
      children: [
        if (saga.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.forest_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),

              const SizedBox(width: AppSpacing.xs),

              Flexible(
                child: Text(
                  saga,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

        if (numeroSaga.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),

          Text(
            'Libro $numeroSaga',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ],
    );
  }
}

// ─── Chip de estado personal (solo visible en modo global) ────────────────────

class _EstadoPersonalChip extends StatelessWidget {
  const _EstadoPersonalChip({required this.estado});

  /// Estado de lectura del usuario actual, o `null` si no lo tiene en biblioteca.
  final String? estado;

  @override
  Widget build(BuildContext context) {
    if (estado == null) {
      // El usuario aún no tiene el libro en su biblioteca
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bookmark_add_outlined,
              size: 16,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              'No está en tu biblioteca',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final (color, icon) = _estadoStyle(estado!);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            'Tu estado: ${ReadingStatusCopy.label(estado!)}',
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static (Color, IconData) _estadoStyle(String estado) {
    switch (estado) {
      case 'LEYENDO':
        return (AppColors.info, Icons.menu_book_rounded);
      case 'FINALIZADO':
        return (AppColors.success, Icons.check_circle_outline_rounded);
      case 'RELECTURA':
        return (AppColors.primary, Icons.replay_rounded);
      case 'PAUSADO':
        return (AppColors.warning, Icons.pause_circle_outline_rounded);
      case 'ABANDONADO':
        return (AppColors.danger, Icons.cancel_outlined);
      default: // PENDIENTE
        return (AppColors.info, Icons.bookmark_outline_rounded);
    }
  }
}
