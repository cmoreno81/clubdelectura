import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../ui/club_section_card.dart';
import '../ui/club_section_title.dart';

class LibroSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool elevated;
  final EdgeInsetsGeometry? padding;

  const LibroSection({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    this.onTap,
    this.elevated = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClubSectionCard(
      onTap: onTap,
      elevated: elevated,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClubSectionTitle(
            icon: icon,
            color: color,
            title: title,
            subtitle: subtitle,
          ),

          if (trailing != null) ...[
            const SizedBox(height: AppSpacing.sm),

            Align(alignment: Alignment.centerRight, child: trailing!),
          ],

          const SizedBox(height: AppSpacing.lg),

          Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.8)),

          const SizedBox(height: AppSpacing.lg),

          child,
        ],
      ),
    );
  }
}
