import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

enum ClubMetricVariant { primary, info, success, warning, danger, neutral }

class ClubMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final ClubMetricVariant variant;
  final bool compact;
  final VoidCallback? onTap;

  const ClubMetric({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.variant = ClubMetricVariant.primary,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors();

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(
          compact ? AppRadius.pill : AppRadius.lg,
        ),
        border: Border.all(color: colors.border),
      ),
      child: compact ? _compactContent(colors) : _regularContent(colors),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          compact ? AppRadius.pill : AppRadius.lg,
        ),
        onTap: onTap,
        child: content,
      ),
    );
  }

  Widget _compactContent(_ClubMetricColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: colors.foreground),
        const SizedBox(width: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            color: colors.foreground,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: colors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _regularContent(_ClubMetricColors colors) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: colors.iconBackground,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, size: 22, color: colors.foreground),
        ),

        const SizedBox(width: AppSpacing.sm),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.section.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.visible,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),

        if (onTap != null)
          Icon(Icons.chevron_right_rounded, size: 20, color: colors.foreground),
      ],
    );
  }

  _ClubMetricColors _resolveColors() {
    switch (variant) {
      case ClubMetricVariant.info:
        return const _ClubMetricColors(
          background: Color(0xFFF1F5FC),
          iconBackground: Color(0xFFDDE8F8),
          border: Color(0xFFD0DFF3),
          foreground: AppColors.info,
        );

      case ClubMetricVariant.success:
        return const _ClubMetricColors(
          background: Color(0xFFF1F8F3),
          iconBackground: Color(0xFFDFF0E4),
          border: Color(0xFFD2E8D8),
          foreground: AppColors.success,
        );

      case ClubMetricVariant.warning:
        return const _ClubMetricColors(
          background: Color(0xFFFFF9EA),
          iconBackground: Color(0xFFFFEDBA),
          border: Color(0xFFF1E2B3),
          foreground: Color(0xFFB48113),
        );

      case ClubMetricVariant.danger:
        return const _ClubMetricColors(
          background: Color(0xFFFFF3F3),
          iconBackground: Color(0xFFFFDDDD),
          border: Color(0xFFF1CCCC),
          foreground: AppColors.danger,
        );

      case ClubMetricVariant.neutral:
        return const _ClubMetricColors(
          background: AppColors.surface,
          iconBackground: AppColors.surfaceSoft,
          border: AppColors.divider,
          foreground: AppColors.textSecondary,
        );

      case ClubMetricVariant.primary:
        return const _ClubMetricColors(
          background: AppColors.surfaceSoft,
          iconBackground: AppColors.primaryLight,
          border: AppColors.border,
          foreground: AppColors.primary,
        );
    }
  }
}

class _ClubMetricColors {
  final Color background;
  final Color iconBackground;
  final Color border;
  final Color foreground;

  const _ClubMetricColors({
    required this.background,
    required this.iconBackground,
    required this.border,
    required this.foreground,
  });
}
