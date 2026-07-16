import 'package:flutter/material.dart';

import '../../models/dashboard.dart';
import '../../models/estado_club.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_book_cover.dart';
import '../common/club_chip.dart';
import 'escenas/escena_votacion.dart';

class DirectorEscenas {
  Widget construir({required EstadoClub estado, required Dashboard dashboard}) {
    switch (estado.contenido) {
      case ContenidoClub.preparando:
        return _preparando();

      case ContenidoClub.candidatas:
        return EscenaVotacion(
          totalCandidatas: dashboard.clubvision.totalCandidatas,
        );

      case ContenidoClub.ganador:
        return _ganador(dashboard);

      case ContenidoClub.lectura:
        return _lectura(dashboard);
    }
  }

  Widget _preparando() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Column(
        children: [
          Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 30),

          SizedBox(height: AppSpacing.sm),

          Text(
            'La próxima lectura',
            textAlign: TextAlign.center,
            style: AppTextStyles.section,
          ),

          SizedBox(height: AppSpacing.xs),

          Text(
            'Muy pronto conoceremos las candidatas.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }

  Widget _ganador(Dashboard dashboard) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: AppColors.gold,
            size: 40,
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            dashboard.clubvision.mensaje,
            textAlign: TextAlign.center,
            style: AppTextStyles.section,
          ),
        ],
      ),
    );
  }

  Widget _lectura(Dashboard dashboard) {
    final lectura = dashboard.lecturaActual;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClubBookCover(
            title: lectura.titulo,
            imageUrl: lectura.coverUrl,
            width: 105,
            showShadow: true,
            heroTag: 'lectura-actual-${lectura.titulo}',
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lectura.titulo,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.section.copyWith(
                    fontSize: 20,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (lectura.comentarios > 0)
                      ClubChip(
                        label: '${lectura.comentarios}',
                        icon: Icons.chat_bubble_outline_rounded,
                        variant: ClubChipVariant.primary,
                      ),

                    if (lectura.likes > 0)
                      ClubChip(
                        label: '${lectura.likes}',
                        icon: Icons.favorite_border_rounded,
                        variant: ClubChipVariant.danger,
                      ),

                    ClubChip(
                      label: '${lectura.totalLeyendo} leyendo',
                      icon: Icons.people_outline_rounded,
                      variant: ClubChipVariant.info,
                    ),

                    ClubChip(
                      label: '${lectura.totalFinalizado} finalizaron',
                      icon: Icons.check_circle_outline_rounded,
                      variant: ClubChipVariant.success,
                    ),
                  ],
                ),

                if (lectura.ultimaActividad.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),

                      const SizedBox(width: AppSpacing.xs),

                      Expanded(
                        child: Text(
                          lectura.ultimaActividad,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
