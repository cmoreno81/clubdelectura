import 'package:flutter/material.dart';

import '../models/como_votaron.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/error_view.dart';

class ClubvisionComoVotaronPage extends StatefulWidget {
  const ClubvisionComoVotaronPage({super.key});

  @override
  State<ClubvisionComoVotaronPage> createState() =>
      _ClubvisionComoVotaronPageState();
}

class _ClubvisionComoVotaronPageState extends State<ClubvisionComoVotaronPage> {
  late Future<List<ComoVotaron>> future;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    future = ApiService().getComoVotaron();
  }

  Future<void> _refrescar() async {
    setState(_recargar);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cómo votaron')),
      body: FutureBuilder<List<ComoVotaron>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(
              onRetry: () {
                setState(_recargar);
              },
            );
          }

          final lista = snapshot.data ?? const <ComoVotaron>[];

          if (lista.isEmpty) {
            return _VotacionesVacias(onRefresh: _refrescar);
          }

          return RefreshIndicator(
            onRefresh: _refrescar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                110,
              ),
              children: [
                _ComoVotaronHeader(totalLectoras: lista.length),

                const SizedBox(height: AppSpacing.xl),

                const _SectionHeader(
                  icon: Icons.groups_2_outlined,
                  color: AppColors.primary,
                  title: 'Las papeletas del club',
                  subtitle: 'Así repartió sus puntos cada lectora',
                ),

                const SizedBox(height: AppSpacing.md),

                for (var index = 0; index < lista.length; index++) ...[
                  _VotanteCard(persona: lista[index]),

                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ComoVotaronHeader extends StatelessWidget {
  final int totalLectoras;

  const _ComoVotaronHeader({required this.totalLectoras});

  @override
  Widget build(BuildContext context) {
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
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.ballot_rounded,
              color: AppColors.primary,
              size: 38,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'Así votó el club',
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 29),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            totalLectoras == 1
                ? 'Una lectora dejó registrada su clasificación.'
                : '$totalLectoras lectoras dejaron registrada su clasificación.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(height: 1.45),
          ),

          const SizedBox(height: AppSpacing.lg),

          ClubChip(
            label: totalLectoras == 1
                ? '1 papeleta'
                : '$totalLectoras papeletas',
            icon: Icons.how_to_vote_outlined,
            variant: ClubChipVariant.primary,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(icon, color: color, size: 27),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.section.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                subtitle,
                style: AppTextStyles.bodySecondary.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VotanteCard extends StatelessWidget {
  final ComoVotaron persona;

  const _VotanteCard({required this.persona});

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClubAvatar(nombre: persona.usuaria, size: 56),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      persona.usuaria,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.section.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      persona.votos.length == 1
                          ? '1 libro clasificado'
                          : '${persona.votos.length} libros clasificados',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),

              const ClubChip(
                label: 'Papeleta',
                icon: Icons.ballot_outlined,
                variant: ClubChipVariant.primary,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          for (var index = 0; index < persona.votos.length; index++) ...[
            _VotoEmitidoRow(posicion: index, voto: persona.votos[index]),

            if (index < persona.votos.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _VotoEmitidoRow extends StatelessWidget {
  final int posicion;
  final VotoEmitido voto;

  const _VotoEmitidoRow({required this.posicion, required this.voto});

  @override
  Widget build(BuildContext context) {
    final color = switch (posicion) {
      0 => const Color(0xFFE4B63F),
      1 => const Color(0xFF9AA3AF),
      2 => const Color(0xFFB77948),
      _ => AppColors.primary,
    };

    final icono = switch (posicion) {
      0 => Icons.emoji_events_rounded,
      1 => Icons.workspace_premium_rounded,
      2 => Icons.workspace_premium_outlined,
      _ => null,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: icono != null
                ? Icon(icono, color: color, size: 25)
                : Text(
                    '${posicion + 1}',
                    style: TextStyle(
                      color: color,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voto.libro,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  '${posicion + 1}.ª posición',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          ClubChip(
            label: '${voto.puntos} pt',
            icon: Icons.star_outline_rounded,
            variant: posicion == 0
                ? ClubChipVariant.warning
                : ClubChipVariant.primary,
          ),
        ],
      ),
    );
  }
}

class _VotacionesVacias extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _VotacionesVacias({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.68,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 74,
                      height: 74,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.ballot_outlined,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Todavía no hay papeletas',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.section,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    const Text(
                      'Cuando las lectoras voten, sus clasificaciones aparecerán aquí.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
