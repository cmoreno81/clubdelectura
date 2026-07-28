import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

class ClubCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool elevated;
  final double? width;

  const ClubCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    this.onTap,
    this.elevated = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final fondo =
        backgroundColor ?? theme.cardTheme.color ?? colorScheme.surface;

    final borde =
        borderColor ??
        theme.dividerTheme.color ??
        colorScheme.outline.withValues(alpha: 0.55);

    final contenido = Container(
      width: width,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: gradient == null ? fondo : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: borde, width: 1),
        boxShadow: elevated ? AppShadows.card : null,
      ),
      child: child,
    );

    if (onTap == null) {
      return contenido;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: contenido,
      ),
    );
  }
}
