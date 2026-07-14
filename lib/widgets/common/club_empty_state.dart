import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'club_button.dart';

class ClubEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  const ClubEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xxl,
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Icon(icon, size: 36, color: AppColors.primary),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.section,
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),

          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),

            ClubButton(
              label: actionLabel!,
              onPressed: onAction,
              expanded: false,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ],
      ),
    );
  }
}
