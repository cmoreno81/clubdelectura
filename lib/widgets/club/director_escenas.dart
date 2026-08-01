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
          portadas: dashboard.clubvision.portadasCandidatas,
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
    final totalVotos = dashboard.clubvision.votosRecibidos;
    final totalMiembros = dashboard.clubvision.totalUsuarios;
    final participacion = totalMiembros > 0
        ? (totalVotos / totalMiembros * 100).round()
        : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8E6), Color(0xFFFFF0C0)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: const Color(0xFFE4B63F).withValues(alpha: .5),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statItem(
                '$totalVotos',
                'votos recibidos',
                Icons.how_to_vote_outlined,
              ),
              Container(
                width: 1,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                color: const Color(0xFFE4B63F).withValues(alpha: .4),
              ),
              _statItem(
                '$participacion%',
                'participación',
                Icons.people_outline_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE4B63F).withValues(alpha: .15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFFE4B63F).withValues(alpha: .4),
              ),
            ),
            child: Text(
              '¡Entra y descubre quién ha ganado! 🏆',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF7A5A00),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFFB48113), size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.title.copyWith(
            fontSize: 32,
            color: const Color(0xFF5A3E00),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: const Color(0xFF9A7A20),
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _lectura(Dashboard dashboard) {
    final lectura = dashboard.lecturaActual;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .88),
            const Color(0xFFEDE3FF).withValues(alpha: .82),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primary.withValues(alpha: .14)),
      ),
      child: Column(
        children: [
          Row(
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
                    const Text(
                      'EL LIBRO DEL CLUB',
                      style: TextStyle(
                        color: AppColors.inkCoral,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      lectura.titulo,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.section.copyWith(
                        fontSize: 20,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        ClubChip(
                          label: '${lectura.totalLeyendo} leyendo',
                          icon: Icons.people_outline_rounded,
                          variant: ClubChipVariant.info,
                        ),
                        ClubChip(
                          label: '${lectura.totalFinalizado} terminaron',
                          icon: Icons.check_circle_outline_rounded,
                          variant: ClubChipVariant.success,
                        ),
                        if (lectura.comentarios > 0)
                          ClubChip(
                            label: '${lectura.comentarios} comentarios',
                            icon: Icons.chat_bubble_outline_rounded,
                            variant: ClubChipVariant.primary,
                          ),
                        if (lectura.likes > 0)
                          ClubChip(
                            label: '${lectura.likes} reacciones',
                            icon: Icons.favorite_border_rounded,
                            variant: ClubChipVariant.danger,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (lectura.ultimaActividad.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .64),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
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
                      style: AppTextStyles.caption.copyWith(height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.forum_outlined, size: 18, color: Colors.white),
                SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    'Entrar al rincón de lectura',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
