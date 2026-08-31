import 'package:flutter/material.dart';

import '../../models/achievements/achievement.dart';
import '../../services/achievement_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

class AchievementsSection extends StatelessWidget {
  const AchievementsSection({super.key, required this.achievements});
  final List<UserAchievement> achievements;

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return const _EmptyAchievements();
    }

    final unlocked = achievements.where((a) => a.unlocked).length;
    final total = achievements.length;

    // Agrupar por categoría
    final Map<String, List<UserAchievement>> byCategory = {};
    for (final a in achievements) {
      byCategory.putIfAbsent(a.category, () => []).add(a);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cabecera global ──
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Logros', style: AppTextStyles.section),
                  Text(
                    '$unlocked de $total desbloqueados',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  total > 0 ? '${(unlocked / total * 100).round()}%' : '0%',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? unlocked / total : 0.0,
                      minHeight: 6,
                      backgroundColor: AppColors.primaryLight,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Una sección por categoría ──
        for (final entry in AchievementService.categoryLabels.entries)
          if (byCategory.containsKey(entry.key)) ...[
            _CategorySection(
              label: entry.value,
              achievements: byCategory[entry.key]!,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.label, required this.achievements});

  final String label;
  final List<UserAchievement> achievements;

  @override
  Widget build(BuildContext context) {
    final unlockedCount = achievements.where((a) => a.unlocked).length;
    final sorted = [...achievements]
      ..sort((a, b) {
        if (a.unlocked && !b.unlocked) return -1;
        if (!a.unlocked && b.unlocked) return 1;
        final aPct = a.target > 0 ? a.progress / a.target : 0.0;
        final bPct = b.target > 0 ? b.progress / b.target : 0.0;
        return bPct.compareTo(aPct);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: unlockedCount > 0
                    ? AppColors.primary.withValues(alpha: .12)
                    : AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '$unlockedCount/${achievements.length}',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  color: unlockedCount > 0
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: AppSpacing.xs,
            mainAxisSpacing: AppSpacing.xs,
            childAspectRatio: 0.72,
          ),
          itemCount: sorted.length,
          itemBuilder: (context, i) => _AchievementTile(achievement: sorted[i]),
        ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});
  final UserAchievement achievement;

  Color get _rarityColor => switch (achievement.rarity) {
    'legendary' => const Color(0xFFD97706),
    'epic' => const Color(0xFF7C3AED),
    'rare' => const Color(0xFF2563EB),
    _ => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;
    final color = unlocked ? _rarityColor : AppColors.textMuted;
    final progress = achievement.progress.clamp(0, achievement.target);
    final pct = achievement.target > 0 ? progress / achievement.target : 0.0;

    return Tooltip(
      message:
          '${achievement.title}\n${achievement.description}\n'
          '$progress/${achievement.target}',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: unlocked
              ? color.withValues(alpha: .08)
              : AppColors.surfaceSoft.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: unlocked
                ? color.withValues(alpha: .3)
                : AppColors.border.withValues(alpha: .5),
            width: unlocked ? 1.5 : 1,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: .12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji con candado si bloqueado
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  achievement.icon,
                  style: TextStyle(
                    fontSize: 26,
                    color: unlocked ? null : Colors.black,
                  ),
                ),
                if (!unlocked)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 9,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: unlocked ? color : AppColors.textSecondary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 3,
                backgroundColor: AppColors.border.withValues(alpha: .4),
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAchievements extends StatelessWidget {
  const _EmptyAchievements();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Aún no hay logros',
            style: AppTextStyles.section,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Sigue leyendo y participando en el club.',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
