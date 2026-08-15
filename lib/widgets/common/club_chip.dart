import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

enum ClubChipVariant { neutral, primary, success, warning, danger, info }

class ClubChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final ClubChipVariant variant;
  final EdgeInsetsGeometry? padding;

  const ClubChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.variant = ClubChipVariant.neutral,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors();

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
      decoration: BoxDecoration(
        color: selected ? colors.backgroundSelected : colors.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: selected ? colors.borderSelected : colors.border,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 17,
              color: selected ? colors.foregroundSelected : colors.foreground,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              softWrap: true,
              style: AppTextStyles.caption.copyWith(
                color: selected ? colors.foregroundSelected : colors.foreground,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return chip;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: chip,
      ),
    );
  }

  _ClubChipColors _resolveColors() {
    switch (variant) {
      case ClubChipVariant.primary:
        return const _ClubChipColors(
          background: AppColors.surfaceSoft,
          backgroundSelected: AppColors.primary,
          border: AppColors.border,
          borderSelected: AppColors.primary,
          foreground: AppColors.primary,
          foregroundSelected: Colors.white,
        );

      case ClubChipVariant.success:
        return const _ClubChipColors(
          background: Color(0xFFF1F8F3),
          backgroundSelected: AppColors.success,
          border: Color(0xFFD7EBDD),
          borderSelected: AppColors.success,
          foreground: AppColors.success,
          foregroundSelected: Colors.white,
        );

      case ClubChipVariant.warning:
        return const _ClubChipColors(
          background: Color(0xFFFFF8EA),
          backgroundSelected: AppColors.warning,
          border: Color(0xFFF4E0B0),
          borderSelected: AppColors.warning,
          foreground: Color(0xFF9A6B10),
          foregroundSelected: AppColors.textPrimary,
        );

      case ClubChipVariant.danger:
        return const _ClubChipColors(
          background: Color(0xFFFFF1F1),
          backgroundSelected: AppColors.danger,
          border: Color(0xFFF3D1D1),
          borderSelected: AppColors.danger,
          foreground: AppColors.danger,
          foregroundSelected: Colors.white,
        );

      case ClubChipVariant.info:
        return const _ClubChipColors(
          background: Color(0xFFF0F4FB),
          backgroundSelected: AppColors.info,
          border: Color(0xFFD5E0F3),
          borderSelected: AppColors.info,
          foreground: AppColors.info,
          foregroundSelected: Colors.white,
        );

      case ClubChipVariant.neutral:
        return const _ClubChipColors(
          background: AppColors.surface,
          backgroundSelected: AppColors.midnight,
          border: AppColors.divider,
          borderSelected: AppColors.midnight,
          foreground: AppColors.textSecondary,
          foregroundSelected: Colors.white,
        );
    }
  }
}

class _ClubChipColors {
  final Color background;
  final Color backgroundSelected;
  final Color border;
  final Color borderSelected;
  final Color foreground;
  final Color foregroundSelected;

  const _ClubChipColors({
    required this.background,
    required this.backgroundSelected,
    required this.border,
    required this.borderSelected,
    required this.foreground,
    required this.foregroundSelected,
  });
}
