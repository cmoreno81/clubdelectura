import 'package:flutter/material.dart';

import '../../models/dashboard.dart';
import '../../services/api_service.dart';
import '../../services/usuario_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_avatar.dart';
import '../common/club_button.dart';
import '../common/club_card.dart';
import '../common/club_chip.dart';

class GalaCard extends StatelessWidget {
  final Dashboard dashboard;

  const GalaCard({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final club = dashboard.clubvision;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cabeceraGala(club.ganador),

        const SizedBox(height: AppSpacing.lg),

        _libroGanador(club),

        const SizedBox(height: AppSpacing.lg),

        _lectorasPrevias(club.lectoras),

        const SizedBox(height: AppSpacing.lg),

        _mensajeFinal(),

        const SizedBox(height: AppSpacing.lg),

        ClubButton(
          label: 'Comenzar lectura',
          icon: Icons.auto_stories_rounded,
          onPressed: () async {
            final usuario = await UsuarioService().obtenerUsuario();

            if (usuario == null || usuario.trim().isEmpty) {
              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No se ha podido identificar a la usuaria.'),
                ),
              );
              return;
            }

            final ok = await ApiService().iniciarLectura(
              usuario: usuario,
              libro: club.ganador,
            );

            if (!context.mounted) return;

            if (!ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No se pudo iniciar la lectura.')),
              );
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '📖 ${club.ganador} ya forma parte de tu biblioteca.',
                ),
              ),
            );

            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }

  Widget _cabeceraGala(String ganador) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.surfaceSoft, Color(0xFFF1E8FF)],
      ),
      borderColor: AppColors.primaryLight,
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEDBA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFB48113),
              size: 42,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'Ya tenemos ganadora',
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 30),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            ganador.trim().isEmpty
                ? 'La próxima lectura está a punto de revelarse.'
                : 'La próxima aventura del club ya tiene nombre.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(height: 1.45),
          ),

          const SizedBox(height: AppSpacing.lg),

          const ClubChip(
            label: 'Ganadora de Clubvisión',
            icon: Icons.emoji_events_outlined,
            variant: ClubChipVariant.warning,
          ),
        ],
      ),
    );
  }

  Widget _libroGanador(dynamic club) {
    return ClubCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.xl),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFBF0), Color(0xFFFFF4D8)],
      ),
      borderColor: const Color(0xFFF1E2B3),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 128,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDBA),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 46,
              color: Color(0xFFB48113),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            club.ganador,
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 30, height: 1.15),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'Elegida por el club',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(fontSize: 17),
          ),

          const SizedBox(height: AppSpacing.lg),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              ClubChip(
                label: 'Lectura oficial',
                icon: Icons.auto_stories_outlined,
                variant: ClubChipVariant.primary,
              ),
              ClubChip(
                label: 'Próxima aventura',
                icon: Icons.auto_awesome_rounded,
                variant: ClubChipVariant.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lectorasPrevias(List<String> lectoras) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ya conocían esta historia',
            style: AppTextStyles.section.copyWith(color: AppColors.textPrimary),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            lectoras.isEmpty
                ? 'Será una lectura completamente nueva para todo el club.'
                : 'Estas lectoras ya habían pasado por sus páginas.',
            style: AppTextStyles.bodySecondary.copyWith(height: 1.4),
          ),

          const SizedBox(height: AppSpacing.lg),

          if (lectoras.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 34,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Estreno para todo el club',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle,
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: lectoras
                  .map(
                    (nombre) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClubAvatar(nombre: nombre, size: 54),
                        const SizedBox(height: AppSpacing.xs),
                        SizedBox(
                          width: 72,
                          child: Text(
                            nombre,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _mensajeFinal() {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF8F3FF), Color(0xFFF1E8FF)],
      ),
      borderColor: AppColors.primaryLight,
      child: const Column(
        children: [
          Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 36),

          SizedBox(height: AppSpacing.md),

          Text(
            'Empieza una nueva aventura',
            textAlign: TextAlign.center,
            style: AppTextStyles.section,
          ),

          SizedBox(height: AppSpacing.sm),

          Text(
            'A partir de ahora, las conversaciones del club girarán alrededor de esta historia. Disfrútala con el resto de lectoras.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}
