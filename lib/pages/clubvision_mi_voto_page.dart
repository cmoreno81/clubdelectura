import 'package:flutter/material.dart';

import '../models/mi_voto.dart';
import '../services/api_service.dart';
import '../services/usuario_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/error_view.dart';

class ClubvisionMiVotoPage extends StatefulWidget {
  const ClubvisionMiVotoPage({super.key});

  @override
  State<ClubvisionMiVotoPage> createState() => _ClubvisionMiVotoPageState();
}

class _ClubvisionMiVotoPageState extends State<ClubvisionMiVotoPage> {
  late Future<MiVoto> future;

  static const List<int> puntos = [12, 10, 8, 7, 6];

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    future = _cargar();
  }

  Future<MiVoto> _cargar() async {
    final usuario = await UsuarioService().obtenerUsuario();

    return ApiService().getMiVoto(usuario?.trim() ?? '');
  }

  Future<void> _refrescar() async {
    setState(_recargar);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi voto')),
      body: FutureBuilder<MiVoto>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorView(
              onRetry: () {
                setState(_recargar);
              },
            );
          }

          final voto = snapshot.data!;

          if (!voto.encontrado) {
            return _VotoNoEncontrado(onRefresh: _refrescar);
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
                _CabeceraMiVoto(voto: voto),

                const SizedBox(height: AppSpacing.xl),

                const _SectionHeader(
                  icon: Icons.ballot_outlined,
                  color: AppColors.primary,
                  title: 'Tu clasificación',
                  subtitle: 'Así repartiste tus puntos entre las candidatas',
                ),

                const SizedBox(height: AppSpacing.md),

                ClubCard(
                  elevated: false,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < voto.votos.length;
                        index++
                      ) ...[
                        _VotoItem(
                          posicion: index,
                          libro: voto.votos[index],
                          puntos: index < puntos.length ? puntos[index] : 0,
                        ),

                        if (index < voto.votos.length - 1)
                          const Divider(
                            height: 1,
                            indent: AppSpacing.md,
                            endIndent: AppSpacing.md,
                          ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                ClubCard(
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
                      Icon(
                        Icons.favorite_rounded,
                        color: AppColors.primary,
                        size: 38,
                      ),

                      SizedBox(height: AppSpacing.md),

                      Text(
                        'Gracias por participar',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.section,
                      ),

                      SizedBox(height: AppSpacing.sm),

                      Text(
                        'Tu selección ya forma parte de la historia de Clubvisión. Ahora solo queda descubrir cuál será la próxima lectura.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CabeceraMiVoto extends StatelessWidget {
  final MiVoto voto;

  const _CabeceraMiVoto({required this.voto});

  @override
  Widget build(BuildContext context) {
    final progreso = voto.totalUsuarios == 0
        ? 0.0
        : voto.votosRecibidos / voto.totalUsuarios;

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
              color: Color(0xFFE9F7EF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 42,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'Tu voto está registrado',
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 29),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            '${voto.votosRecibidos} de '
            '${voto.totalUsuarios} lectoras ya han votado',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(height: 1.4),
          ),

          const SizedBox(height: AppSpacing.lg),

          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progreso.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.75),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ClubChip(
                label: '${voto.votosRecibidos} votos',
                icon: Icons.how_to_vote_outlined,
                variant: ClubChipVariant.primary,
              ),
              ClubChip(
                label: '${voto.votosPendientes} pendientes',
                icon: Icons.schedule_rounded,
                variant: ClubChipVariant.warning,
              ),
            ],
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
            color: color.withValues(alpha: 0.13),
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

class _VotoItem extends StatelessWidget {
  final int posicion;
  final String libro;
  final int puntos;

  const _VotoItem({
    required this.posicion,
    required this.libro,
    required this.puntos,
  });

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

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: icono != null
                ? Icon(icono, color: color, size: 27)
                : Text(
                    '${posicion + 1}',
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
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
                  libro,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
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
            label: '$puntos puntos',
            icon: Icons.star_outline_rounded,
            variant: ClubChipVariant.primary,
          ),
        ],
      ),
    );
  }
}

class _VotoNoEncontrado extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _VotoNoEncontrado({required this.onRefresh});

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
                      'No hemos encontrado tu voto',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.section,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    const Text(
                      'Puede que todavía no hayas participado en esta edición.',
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
