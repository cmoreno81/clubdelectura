import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'common/club_card.dart';

enum InfoCardVariant { primary, blush, sage, warning, gold, info }

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final InfoCardVariant variant;
  final bool compact;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
    this.variant = InfoCardVariant.primary,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors();

    return ClubCard(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      backgroundColor: colors.background,
      borderColor: colors.border,
      elevated: !compact,
      onTap: onTap,
      child: compact ? _compactContent(colors) : _regularContent(colors),
    );
  }

  Widget _regularContent(_InfoCardColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: colors.iconBackground,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(icon, size: 27, color: colors.foreground),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(value, style: AppTextStyles.bodySecondary),
            ],
          ),
        ),

        if (onTap != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.chevron_right_rounded, color: colors.foreground),
        ],
      ],
    );
  }

  Widget _compactContent(_InfoCardColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.iconBackground,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 21, color: colors.foreground),
            ),

            const Spacer(),

            if (onTap != null)
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: colors.foreground,
              ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.section.copyWith(fontSize: 19),
        ),

        const SizedBox(height: AppSpacing.xs),

        Text(
          title,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  _InfoCardColors _resolveColors() {
    switch (variant) {
      case InfoCardVariant.blush:
        return const _InfoCardColors(
          background: Color(0xFFFFF4F7),
          border: Color(0xFFF5D8E1),
          iconBackground: Color(0xFFFFE3EC),
          foreground: Color(0xFFD95781),
        );

      case InfoCardVariant.sage:
        return const _InfoCardColors(
          background: Color(0xFFF4FAF5),
          border: Color(0xFFD9EBDD),
          iconBackground: Color(0xFFE3F2E6),
          foreground: Color(0xFF5C986A),
        );

      case InfoCardVariant.warning:
        return const _InfoCardColors(
          background: Color(0xFFFFF7EC),
          border: Color(0xFFF3DFC0),
          iconBackground: Color(0xFFFFE9C6),
          foreground: Color(0xFFD98324),
        );

      case InfoCardVariant.gold:
        return const _InfoCardColors(
          background: Color(0xFFFFFBEF),
          border: Color(0xFFF1E2B3),
          iconBackground: Color(0xFFFFF0B8),
          foreground: Color(0xFFB48113),
        );

      case InfoCardVariant.info:
        return const _InfoCardColors(
          background: Color(0xFFF3F7FD),
          border: Color(0xFFD6E2F4),
          iconBackground: Color(0xFFE2EBFA),
          foreground: AppColors.info,
        );

      case InfoCardVariant.primary:
        return const _InfoCardColors(
          background: AppColors.surfaceSoft,
          border: AppColors.border,
          iconBackground: AppColors.primaryLight,
          foreground: AppColors.primary,
        );
    }
  }
}

class _InfoCardColors {
  final Color background;
  final Color border;
  final Color iconBackground;
  final Color foreground;

  const _InfoCardColors({
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.foreground,
  });
}
