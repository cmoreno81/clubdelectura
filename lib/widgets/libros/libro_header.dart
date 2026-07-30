import 'package:flutter/material.dart';

import '../../models/libro.dart';
import '../../models/libro_agrupado.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/genero_utils.dart';
import '../common/club_book_cover.dart';
import '../common/club_card.dart';
import '../ui/club_metric.dart';
import '../ui/club_section_card.dart';

class LibroHeader extends StatelessWidget {
  final LibroAgrupado libro;
  final Libro? referencia;
  final VoidCallback? onAbrirGoodreads;

  const LibroHeader({
    super.key,
    required this.libro,
    required this.referencia,
    this.onAbrirGoodreads,
  });

  @override
  Widget build(BuildContext context) {
    final tieneGoodreads = referencia?.goodreads.trim().isNotEmpty ?? false;

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
                showShadow: true,
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

              Row(
                children: [
                  Expanded(
                    child: ClubMetric(
                      icon: Icons.people_outline_rounded,
                      value: '${libro.total}',
                      label: 'interesadas',
                      variant: ClubMetricVariant.info,
                      compact: true,
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  Expanded(
                    child: ClubMetric(
                      icon: Icons.check_circle_outline_rounded,
                      value: '${libro.totalFinalizados}',
                      label: 'leídos',
                      variant: ClubMetricVariant.success,
                      compact: true,
                    ),
                  ),
                ],
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

                      const Text(
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
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
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
