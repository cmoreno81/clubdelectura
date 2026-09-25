import 'package:flutter/material.dart';

import '../../models/achievements/achievement.dart';
import '../../navigation/app_page_route.dart';
import '../../pages/mis_logros_page.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_shimmer.dart';

/// Bingo lector: los logros de siempre, pero como cartón de bingo en vez de
/// lista — pensado para que apetezca volver a mirarlo. El orden es siempre
/// el que da el backend, para que cada casilla se quede en su sitio de una
/// visita a otra en vez de saltar al desbloquear cosas.
class BingoLectorSection extends StatelessWidget {
  const BingoLectorSection({super.key, required this.future});
  final Future<List<UserAchievement>> future;

  static const _casillas = 25;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserAchievement>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BingoSkeleton();
        }
        final achievements = snapshot.data ?? const [];
        if (achievements.isEmpty) return const SizedBox.shrink();

        final unlocked = achievements.where((a) => a.unlocked).length;
        final total = achievements.length;
        final pct = total > 0 ? unlocked / total : 0.0;
        final casillas = achievements.take(_casillas).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 22)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bingo lector ${DateTime.now().year}',
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '$unlocked de $total casillas',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push<void>(
                    context,
                    AppPageRoute(builder: (_) => const MisLogrosPage()),
                  ),
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: AppColors.primaryLight,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemCount: casillas.length,
              itemBuilder: (context, i) => BingoCell(achievement: casillas[i]),
            ),
          ],
        );
      },
    );
  }
}

/// Placeholder con las mismas dimensiones que el cartón cargado, para no
/// dar un salto de layout mientras el future de achievements está en vuelo.
class BingoSkeleton extends StatelessWidget {
  const BingoSkeleton({super.key});

  static BorderRadius _r(double r) => BorderRadius.circular(r);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClubShimmer(width: 24, height: 24, borderRadius: _r(4)),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClubShimmer(width: 140, height: 14, borderRadius: _r(4)),
                  const SizedBox(height: 4),
                  ClubShimmer(width: 100, height: 11, borderRadius: _r(4)),
                ],
              ),
            ),
            ClubShimmer(width: 60, height: 28, borderRadius: _r(8)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClubShimmer(width: double.infinity, height: 6, borderRadius: _r(3)),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: 25,
          itemBuilder: (_, i) =>
              ClubShimmer(width: double.infinity, height: double.infinity, borderRadius: _r(8)),
        ),
      ],
    );
  }
}

/// Una casilla del cartón: sellada (con su check dorado) si está
/// desbloqueada, apagada con el progreso debajo si no.
class BingoCell extends StatelessWidget {
  const BingoCell({super.key, required this.achievement});
  final UserAchievement achievement;

  Color get _color => switch (achievement.rarity) {
    'legendary' => AppColors.gold,               // dorado
    'epic'      => AppColors.primary,            // ciruela
    'rare'      => const Color(0xFF5A7A60),      // salvia tierra
    _           => AppColors.textSecondary,      // marrón grisáceo — común
  };

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;
    final color = _color;
    final progresoTexto = !unlocked && achievement.target > 1
        ? '${achievement.progress}/${achievement.target}'
        : null;
    return Tooltip(
      message: unlocked
          ? '${achievement.title}\n${achievement.description}'
          : '${achievement.title}\n${achievement.description}'
                '${progresoTexto != null ? '\n$progresoTexto' : ''}',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: unlocked
                  ? color.withValues(alpha: .16)
                  : AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: unlocked ? color.withValues(alpha: .55) : AppColors.border,
                width: unlocked ? 1.6 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: unlocked ? 1 : .32,
              child: Text(
                achievement.icon,
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ),
          if (progresoTexto != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 2,
              child: Text(
                progresoTexto,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          if (unlocked)
            Positioned(
              right: -4,
              top: -4,
              child: Transform.rotate(
                angle: -0.35,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: .5),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 9,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
